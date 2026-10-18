window.__ModuleLoader__.load({
  id: '@local/dsh-effort-slider',
  factory(require) {
    const React = require('react');
    const h = React.createElement;

    /**
     * Replaces the composer's model control with a card that keeps the shipped
     * two-row shape — 模型 above, 推理等级 below — and swaps the reasoning row's
     * menu for a four-stop slider. The art follows the Codex reference: a
     * blue-to-violet pill with faint specks and a white knob.
     */
    const CSS = [
      '.dsh-mc-root{position:relative;display:inline-flex;font:inherit}',
      '.dsh-mc-pop,.dsh-mc-pop *{box-sizing:border-box}',
      '.dsh-mc-trigger{display:inline-flex;align-items:center;gap:6px;height:24px;padding:0 8px;border:0;',
      'border-radius:6px;background:transparent;color:var(--dsw-alias-label-primary,#e6e6ea);',
      'font:inherit;font-size:12px;line-height:1;cursor:pointer;white-space:nowrap}',
      '.dsh-mc-trigger:hover{background:var(--dsw-alias-bg-layer-2,rgba(255,255,255,.06))}',
      '.dsh-mc-trigger[data-open="1"]{background:var(--dsw-alias-bg-layer-2,rgba(255,255,255,.08))}',
      '.dsh-mc-effort{color:var(--dsw-alias-label-caption,#9a9aa5)}',
      '.dsh-mc-caret{opacity:.55;font-size:9px}',
      '.dsh-mc-pop{position:absolute;z-index:40;right:0;bottom:calc(100% + 6px);width:340px;padding:6px;',
      'border-radius:12px;border:1px solid var(--dsw-alias-border-l2,rgba(255,255,255,.1));',
      'background:var(--dsw-alias-bg-layer-2,#242429);box-shadow:0 12px 32px rgba(0,0,0,.45)}',
      '.dsh-mc-row{display:flex;align-items:center;justify-content:space-between;gap:10px;width:100%;',
      'padding:0 8px;height:34px;border:0;border-radius:8px;background:transparent;color:inherit;',
      'font:inherit;font-size:13px;text-align:left}',
      'button.dsh-mc-row{cursor:pointer}',
      'button.dsh-mc-row:hover{background:var(--dsw-alias-bg-layer-3,rgba(255,255,255,.07))}',
      '.dsh-mc-value{color:var(--dsw-alias-label-caption,#9a9aa5);font-size:12px;white-space:nowrap}',
      '.dsh-mc-effort-row{padding-right:6px}',
      '.dsh-effort{display:inline-flex;align-items:center;gap:8px}',
      // The track paints once: a violet base and a fixed blue-to-violet face, so
      // a compositing gap can never show black. Motion rides on top in two
      // layers that animate transform only — no blend modes, no filters.
      '.dsh-effort-track{position:relative;width:124px;height:24px;border-radius:999px;overflow:hidden;',
      'background:#3a2a92;cursor:pointer;touch-action:none;outline:none;',
      'box-shadow:inset 0 1px 0 rgba(255,255,255,.22),inset 0 -1px 0 rgba(0,0,0,.18),',
      '0 2px 10px rgba(80,60,200,.35),0 0 12px rgba(150,110,255,.28)}',
      '.dsh-effort-track:focus-visible{box-shadow:inset 0 1px 0 rgba(255,255,255,.22),0 0 0 2px rgba(150,160,255,.7)}',
      '.dsh-effort-base{position:absolute;inset:0;border-radius:inherit;pointer-events:none;',
      'background:linear-gradient(90deg,#2f6bf0 0%,#5b57f5 42%,#8b45f6 72%,#a855f7 100%)}',
      // Neon sweep: a soft band of light travelling along the track.
      '.dsh-effort-sweep{position:absolute;top:0;bottom:0;left:0;width:200%;pointer-events:none;',
      'will-change:transform;opacity:.4;',
      // The gradient repeats every 50% of this 200%-wide layer, so translating
      // it by exactly -50% lands on an identical picture: no seam, no jump.
      'background:linear-gradient(90deg,rgba(255,255,255,0) 0%,rgba(214,222,255,.16) 8%,',
      'rgba(238,230,255,.34) 14%,rgba(214,222,255,.16) 20%,rgba(255,255,255,0) 26%,',
      'rgba(255,255,255,0) 50%,rgba(214,222,255,.16) 58%,rgba(238,230,255,.34) 64%,',
      'rgba(214,222,255,.16) 70%,rgba(255,255,255,0) 76%,rgba(255,255,255,0) 100%);',
      'animation:dsh-effort-sweep 4.8s linear infinite}',
      '@keyframes dsh-effort-sweep{from{transform:translateX(-50%)}to{transform:translateX(0)}}',
      // Stars ride the same current, faster, so the light has depth.
      '.dsh-effort-stars{position:absolute;top:0;bottom:0;left:0;width:300%;pointer-events:none;',
      'will-change:transform;opacity:.95;background-repeat:repeat-x;background-size:124px 100%;',
      'background-image:',
      'radial-gradient(circle at 7px 7px,rgba(255,255,255,.95) 1.1px,transparent 1.8px),',
      'radial-gradient(circle at 29px 16px,rgba(255,255,255,.6) 1px,transparent 1.7px),',
      'radial-gradient(circle at 48px 9px,rgba(255,255,255,.8) 1px,transparent 1.7px),',
      'radial-gradient(circle at 71px 18px,rgba(255,255,255,.55) 1px,transparent 1.7px),',
      'radial-gradient(circle at 92px 11px,rgba(255,255,255,.85) 1px,transparent 1.7px),',
      'radial-gradient(circle at 113px 19px,rgba(255,255,255,.5) 1px,transparent 1.7px);',
      'animation:dsh-effort-stars 4.2s linear infinite}',
      '@keyframes dsh-effort-stars{from{transform:translateX(0)}to{transform:translateX(-124px)}}',
      '.dsh-effort-knob{position:absolute;z-index:5;top:50%;left:0;margin-top:-10px;width:20px;height:20px;',
      'border-radius:50%;background:#fff;pointer-events:none;will-change:transform;',
      'transform:translateX(calc(2px + 100px * var(--dsh-effort-k,0)));',
      'transition:transform 110ms cubic-bezier(.32,.72,0,1);',
      'box-shadow:0 0 0 1px rgba(255,255,255,.92),0 1px 3px rgba(50,40,120,.28),0 0 14px rgba(210,200,255,.9)}',
      '.dsh-effort-track[data-dragging="1"] .dsh-effort-knob{transition:none}',
      // Free the compositor while dragging, so the knob never competes with the
      // ambient animation for a frame.
      '.dsh-effort-track[data-dragging="1"] .dsh-effort-sweep,',
      '.dsh-effort-track[data-dragging="1"] .dsh-effort-stars{animation-play-state:paused}',
      '.dsh-effort-label{font-size:12px;line-height:1;color:var(--dsw-alias-label-primary,#e6e6ea);',
      'min-width:30px;text-align:right;flex:0 0 auto}',
      '@media (prefers-reduced-motion: reduce){',
      '.dsh-effort-sweep,.dsh-effort-stars{animation:none}',
      '.dsh-effort-knob{transition:none}}',
    ].join('');

    /** Model selector inside the composer tool row; this plugin owns the card. */
    const SLOT = 'conversation.input.model';

    /** Remote calls answer with a RemoteResult envelope { ok, value }. */
    function unwrap(response) {
      if (response && typeof response === 'object' && 'ok' in response && 'value' in response) {
        if (response.ok === false) {
          const failure = response.error || response.value;
          throw new Error((failure && (failure.message || failure.code)) || 'remote call failed');
        }
        return response.value;
      }
      return response;
    }

    function remoteSession(ctx, sessionId) {
      const get = (key) => { try { return ctx.get ? ctx.get(key) : undefined; } catch (unavailable) { return undefined; } };
      const sessions = get('sessions');
      if (sessions && typeof sessions.scope === 'function' && sessionId) {
        try {
          const scoped = sessions.scope(sessionId);
          const scopedRemote = scoped && (scoped.remote || (scoped.get && scoped.get('remote')));
          if (scopedRemote && scopedRemote.session) return scopedRemote.session;
        } catch (unavailable) { /* fall through */ }
      }
      const remote = get('remote');
      if (remote && remote.session) return remote.session;
      return undefined;
    }

    /** Four-stop slider. `efforts` is the model's declared list, in order. */
    function EffortSlider(props) {
      const { efforts, index, busy, onPick } = props;
      const count = efforts.length;
      // The drag path is imperative on purpose: a pointermove writes one CSS
      // variable on the track, so React never renders and the knob moves on the
      // compositor. React only learns the result on pointerup.
      const shown = index;

      function ratioAt(el, clientX) {
        if (!el) return 0;
        const rect = el.getBoundingClientRect();
        const pad = 12;
        const span = rect.width - pad * 2;
        if (span <= 0) return 0;
        return Math.min(1, Math.max(0, (clientX - rect.left - pad) / span));
      }
      function indexAt(el, clientX) {
        return Math.round(ratioAt(el, clientX) * (count - 1));
      }
      // Writes the knob position straight to CSS; no render, no layout read
      // after this point. `el` is the track.
      function moveKnob(el, clientX) {
        const ratio = ratioAt(el, clientX);
        el.style.setProperty('--dsh-effort-k', ratio.toFixed(4));
        el.setAttribute('aria-valuenow', String(Math.round(ratio * (count - 1))));
      }

      // Drag state lives on the element: a re-render rebuilds every local here,
      // so a closure flag would reset between pointerdown and pointerup.
      function onPointerDown(event) {
        if (!event.isPrimary) return;
        const el = event.currentTarget;
        el.dataset.dragging = '1';
        if (el.setPointerCapture) { try { el.setPointerCapture(event.pointerId); } catch (unavailable) { /* ignore */ } }
        moveKnob(el, event.clientX);
        event.preventDefault();
      }
      function onPointerMove(event) {
        const el = event.currentTarget;
        if (el.dataset.dragging !== '1') return;
        moveKnob(el, event.clientX);
      }
      function onPointerUp(event) {
        const el = event.currentTarget;
        if (el.dataset.dragging !== '1') return;
        delete el.dataset.dragging;
        if (el.releasePointerCapture) { try { el.releasePointerCapture(event.pointerId); } catch (unavailable) { /* ignore */ } }
        const landed = indexAt(el, event.clientX);
        onPick(landed);
      }
      function onKeyDown(event) {
        if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight' && event.key !== 'Home' && event.key !== 'End') return;
        event.preventDefault();
        let next = shown;
        if (event.key === 'ArrowLeft') next = Math.max(0, shown - 1);
        else if (event.key === 'ArrowRight') next = Math.min(count - 1, shown + 1);
        else if (event.key === 'Home') next = 0;
        else next = count - 1;
        onPick(next);
      }

      const pct = count < 2 ? 0 : shown / (count - 1);
      const current = efforts[shown];


      // No busy styling: any visual change on commit reads as a blink, and the
      // request settles in tens of milliseconds anyway.
      return h('div', { className: 'dsh-effort' },
        h('div', {
          className: 'dsh-effort-track',
          role: 'slider',
          tabIndex: 0,
          'aria-label': 'Reasoning effort',
          'aria-valuemin': 0,
          'aria-valuemax': count - 1,
          'aria-valuenow': shown,
          'aria-valuetext': current ? (current.name || current.id) : '',
          style: { '--dsh-effort-k': pct.toFixed(4) },
          onPointerDown,
          onPointerMove,
          onPointerUp,
          onPointerCancel: onPointerUp,
          onKeyDown,
        },
          h('span', { key: 'base', className: 'dsh-effort-base' }),
          h('span', { key: 'sweep', className: 'dsh-effort-sweep' }),
          h('span', { key: 'stars', className: 'dsh-effort-stars' }),
          h('span', { key: 'knob', className: 'dsh-effort-knob' })),
        h('span', { key: 'label', className: 'dsh-effort-label' }, current ? (current.name || current.id) : ''));
    }

    function createModelCard(ctx) {
      return function ModelCard(props) {
        const sessionId = props.sessionId;

        // The session's live selection lives in the modelSelection projection;
        // catalog.default only covers Sessions that never chose.
        const projected = (() => {
          try {
            const raw = props.useProjection ? props.useProjection('modelSelection') : undefined;
            const snapshot = raw && typeof raw.getSnapshot === 'function' ? raw.getSnapshot() : raw;
            if (!snapshot) return undefined;
            return snapshot.next || snapshot.lastUsed || undefined;
          } catch (unavailable) { return undefined; }
        })();

        const [catalog, setCatalog] = React.useState(null);
        const [open, setOpen] = React.useState(false);
        const [tab, setTab] = React.useState('main');
        const [busy, setBusy] = React.useState(false);
        const [error, setError] = React.useState('');

        React.useEffect(() => {
          const session = remoteSession(ctx, sessionId);
          let live = true;
          if (!session || !sessionId) return undefined;
          Promise.resolve().then(() => session.modelCatalog()).then((response) => {
            if (!live) return;
            setCatalog(unwrap(response));
          }).catch((failure) => {
            if (live) setError(String((failure && failure.message) || failure));
          });
          return () => { live = false; };
        }, [sessionId]);

        React.useEffect(() => {
          if (!open) return undefined;
          const onDown = (event) => {
            const root = event.target && event.target.closest ? event.target.closest('.dsh-mc-root') : null;
            if (!root) setOpen(false);
          };
          const onKey = (event) => { if (event.key === 'Escape') setOpen(false); };
          document.addEventListener('pointerdown', onDown, true);
          document.addEventListener('keydown', onKey);
          return () => {
            document.removeEventListener('pointerdown', onDown, true);
            document.removeEventListener('keydown', onKey);
          };
        }, [open]);

        const selection = projected && projected.model ? projected : (catalog && catalog.default);
        const groups = (catalog && catalog.groups) || [];
        let entry;
        for (const group of groups) {
          if (!selection || group.id !== selection.provider) continue;
          for (const model of group.models || []) if (model.id === selection.model) entry = model;
        }
        const efforts = (entry && entry.reasoning && entry.reasoning.efforts) || [];
        const wanted = (selection && selection.reasoningEffort) || (entry && entry.reasoning && entry.reasoning.defaultEffort);
        const index = Math.max(0, efforts.findIndex((effort) => effort.id === wanted));
        const currentEffort = efforts[index];

        function commit(next) {
          if (!sessionId || !selection) return;
          const target = remoteSession(ctx, sessionId);
          if (!target || typeof target.selectModel !== 'function') return;
          const request = {
            sessionId,
            provider: next.provider || selection.provider,
            model: next.model || selection.model,
            reasoningEffort: next.reasoningEffort === undefined ? wanted : next.reasoningEffort,
          };
          if (!request.reasoningEffort) delete request.reasoningEffort;
          setBusy(true);
          setError('');
          Promise.resolve(target.selectModel(request)).then((response) => {
            unwrap(response);
            setBusy(false);
          }).catch((failure) => {
            setBusy(false);
            setError(String((failure && failure.message) || failure));
          });
        }

        function pickEffort(nextIndex) {
          const next = efforts[nextIndex];
          if (!next || nextIndex === index) return;
          commit({ reasoningEffort: next.id });
        }

        if (!selection) return null;

        const label = entry ? entry.name : selection.model;
        const effortLabel = currentEffort ? (currentEffort.name || currentEffort.id) : '';

        const modelRows = groups.map((group) => h('div', { key: 'group-' + group.id },
          h('div', { key: 'head', style: { padding: '6px 8px 2px', fontSize: 11, opacity: 0.6 } }, group.name || group.id),
          (group.models || []).map((model) => h('button', {
            key: model.id,
            type: 'button',
            className: 'dsh-mc-row',
            onClick: () => { setTab('main'); commit({ provider: group.id, model: model.id }); },
          },
            h('span', null, model.name || model.id),
            model.id === selection.model && group.id === selection.provider
              ? h('span', { className: 'dsh-mc-value' }, '✓')
              : null))));

        const popChildren = tab === 'main'
          ? [
            h('button', {
              key: 'model-row', type: 'button', className: 'dsh-mc-row',
              onClick: () => setTab('models'),
            },
              h('span', { key: 'label' }, '模型'),
              h('span', { key: 'value', className: 'dsh-mc-value' }, label + ' \u203a')),
            h('div', { key: 'effort-row', className: 'dsh-mc-row dsh-mc-effort-row' },
              h('span', { key: 'label' }, '推理等级'),
              efforts.length >= 2
                ? h(EffortSlider, { key: 'slider', efforts, index, busy, onPick: pickEffort })
                : h('span', { key: 'value', className: 'dsh-mc-value' }, error || '无可选等级')),
          ]
          : [
            h('button', {
              key: 'back', type: 'button', className: 'dsh-mc-row',
              onClick: () => setTab('main'),
            }, h('span', null, '\u2039 模型')),
            modelRows,
          ];

        const trigger = h('button', {
          key: 'trigger',
          type: 'button',
          className: 'dsh-mc-trigger',
          'data-open': open ? '1' : '0',
          'aria-haspopup': 'dialog',
          'aria-expanded': open ? 'true' : 'false',
          title: error || undefined,
          onClick: () => { setOpen((prev) => !prev); setTab('main'); },
        },
          h('span', { key: 'name' }, label),
          effortLabel ? h('span', { key: 'effort', className: 'dsh-mc-effort' }, effortLabel) : null,
          h('span', { key: 'caret', className: 'dsh-mc-caret' }, open ? '\u25be' : '\u25b4'));

        const popover = open
          ? h('div', { key: 'pop', className: 'dsh-mc-pop', role: 'dialog' }, popChildren)
          : null;

        return h('div', { className: 'dsh-mc-root' },
          h('style', { key: 'css' }, CSS),
          trigger,
          popover);
      };
    }

    return {
      // Cordis validates nested property access against this list: reading
      // ctx.get('remote').session needs BOTH `remote` and `remote.session`.
      inject: ['slots', 'sessions', 'remote', 'remote.session'],
      apply(ctx) {
        ctx.slots.inject(SLOT, () => ctx.slots.register({
          name: SLOT,
          id: 'effort-slider-model-card',
          // A `single` slot needs a distinct priority to shadow the shipped
          // registration instead of colliding with it at priority 0.
          priority: -1,
        }, createModelCard(ctx)));
      },
    };
  },
});
