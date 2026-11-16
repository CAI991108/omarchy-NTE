import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "zcai.voxtype"

  // 命令交给 bash -lc 执行，~ 由 shell 展开（仓库约定不留绝对家目录）。
  readonly property string ctl: "~/.local/bin/voxtype-ctl"

  property string state: "unknown"   // running | stopped
  property string model: ""
  property string backend: ""

  readonly property bool running: state === "running"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: statusProc
    command: ["bash", "-lc", root.ctl + " status"]
    onExited: function(code) { refreshTimer.restart() }
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = String(text || "").split("·").map(function (s) { return s.trim() })
        root.state = parts[0] || "unknown"
        root.model = parts[1] || ""
        root.backend = parts[2] || ""
      }
    }
  }

  // 点击只做启停。模型切换在 omarchy 主菜单里（Voxtype → 模型：…），
  // 不从组件弹菜单：实测这个组件上右键收不到，左键弹菜单也会被同一次点击关掉。
  Process {
    id: actionProc
    onExited: function(code) { root.refresh() }
  }

  Timer {
    id: refreshTimer
    interval: 4000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.running ? "󰍬" : "󰍭"
    active: root.running
    tooltipText: "voxtype · " + root.state + (root.model ? " · " + root.model : "")
    onPressed: function(b) {
      if (actionProc.running) return
      actionProc.command = ["bash", "-lc", root.ctl + " " + (root.running ? "stop" : "warm")]
      actionProc.running = true
    }
  }
}
