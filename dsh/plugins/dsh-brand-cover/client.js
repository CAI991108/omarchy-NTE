window.__ModuleLoader__.load({
  id: '@local/dsh-brand-cover',
  factory(require) {
    const React = require('react');
    const h = React.createElement;

    // The cover image is inlined so the Client needs no server route and no
    // filesystem access: one 1 KB WebP becomes a ~1.4 KB data URI.
    const COVER = 'data:image/webp;base64,UklGRgoEAABXRUJQVlA4TP4DAAAvh8FnEKfAJgCANCfWQGtQgKLU4nRneloNJQEAJPgCJxPtB4MZwgY+uDANACANXqkkvuU4rnBPJJvOf/zv/3zgnsFiw16x2Is+EtCnzVxslrIGbmq4NiGiaasoxjxcoJ6T7kHSZkoH2pIkx42kAYW5gE3Magb6/68Ny0KRezyVRfR/Aj7/upX+8791nUr2Si+7zidcttKSL6zr6fgnrez6nuzP4woXCut5n9vq+Adl1/HuK2zHlb5+p7Qtbcdmd2y2sF4nbHbHht2O6zZ1bMcVXoeT3Y53W+HEXt6OzRbW3YQNO8YpfIUrbVy3PRbW2YQtvKPs9diyO7b0wrqasIXLXv/YsuO6TVxnE65/rULq2OyODYX1M2FHEq7bTnw+FpLfwoX1MmGzheu2E9c/tpDaceL6mLDZwnXbict+4z8Xex1pobA+1lG40r8x7h1Ob3weFnodmy1cKKyL8Ur/ticuO86nN3oT87Gw2x4LFwrrX8KJ6zHzLfznasfrYcL12OfWbad9HxZ29Dp6XO8SrscWrscWPl9H4Qqvg03898T3myjs2Gxh3Uu47Gm/MZ/sfw8T45haeD1sonBhPuFXPDfx3EQSXvgVhc/R7fqXcNmy38c94Ve8kH7YeSYu2+Pn8TsS172EHzy3wumyaYXf70e40OOJeX6h7F8orG+x8IPChbSOCy9bx5/jCv+Kwnzs/cRfdr2LZVNeuu+VXsfJF95Pdt1LODGfjn+xB068bh8Xf6EwH08kXljfEk6btn3uwolfwokn5pv4JXyg5+eb4fUt2TM8buK240ba5/M93sfPsbB+JXumjRuYZ6W930g/8bm4biXsONN2jJtIwhfG/Qmn67a00ns7bZ3rg8Ke/pzwFX7hRG/az/En/H7Cmb5+xUpLLCSO+4Eve9rX4048N/HCOtl5ij/3A1/2D3zh9fjz+GXX0XwaKCQWvuwf+LKf75VWuI8Lu10XEw47bqCQ4p/rlf5+8XWwjcRC4olC73r8PMJ9XDhQeM6vcwm37bGQhANlf8Pn4jjhtgeeYyEJ62Ic5xPTQIV/w/sxCbct3LZwhBMPVHh9S7hRSMMWjrTEPVzh32w95raF4ziNtHWxjfeR3ZE6krAj9bS0beE4Lhzp61y+J9zh5xoKpy2bhB11vKHSjrR1sg8K8zDJPucLf6NwHhdOjBvp82y7/sXbHujxX0gd42T/xr/xO8qO4257G+OE4/gOr3/t8DjZze4oJCb+jsIZLpzYsaFw4LbrZky8jz+HP5F4ojAP0w6njfm47sWe8JxwoNdxYkOaKOwY5zf0hPt4/Uy4UXaccNjUcWJD4bSpocfU7Pv49TWOY2HDjg1lN5v8jnHCN+bjfFy/Ag==';

    /** Gentle float plus a soft glow for the hero mark; still for reduced motion. */
    const HERO_CSS = [
      '@keyframes bc-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-9px)}}',
      '.bc-hero{animation:bc-float 7s ease-in-out infinite;will-change:transform}',
      '@media (prefers-reduced-motion: reduce){.bc-hero{animation:none}}',
    ].join('');

    /** The hero mark is scaled up from the square edge its owner requests. */
    const HERO_SCALE = 2.2;

    /** The sidebar mark sits in the owner's 24px brand row. */
    const SIDEBAR_SCALE = 1.33;

    /**
     * The owner's brand button clips at 24px; its 60px logo row has the room.
     * `:has()` targets that row without depending on hashed class names, and an
     * engine without it simply keeps the old clipped layout.
     */
    const SIDEBAR_CSS = [
      'button:has(> span > span > div > img.bc-sidebar-mark){overflow:visible}',
      'span:has(> span > div > img.bc-sidebar-mark){overflow:visible}',
    ].join('');

    /**
     * The New Session hero's preview badge ships as a fixed locale string
     * ("预览版" / "Preview"). Its locale namespace is single-occupant, so a
     * Plugin cannot register a competing dictionary; the badge span is the
     * surface instead: hide the shipped glyphs and let a pseudo-element speak
     * the owner's label. Both classes carry a build hash but keep the
     * `titleGroup` / `previewBadge` suffix, and the two-part selector outranks
     * the owner's single-class rule regardless of stylesheet order.
     */
    const PREVIEW_LABEL = '哦鲸鲸...';
    const PREVIEW_CSS = [
      '[class*="titleGroup"] > [class*="previewBadge"]{font-size:0}',
      '[class*="titleGroup"] > [class*="previewBadge"]::after{content:',
      JSON.stringify(PREVIEW_LABEL),
      ';font-size:12px}',
    ].join('');

    function coverImage(px, radius, position, className) {
      return h('img', {
        className: className,
        src: COVER,
        alt: '',
        'aria-hidden': true,
        draggable: false,
        style: {
          display: 'block',
          width: px + 'px',
          height: px + 'px',
          objectFit: 'cover',
          objectPosition: position,
          borderRadius: radius,
          userSelect: 'none',
        },
      });
    }

    /** Sidebar slot: static, compact, rounded square so the rail stays tidy. */
    function SidebarMark(props) {
      const base = typeof props?.size === 'number' && props.size > 0 ? props.size : 24;
      const size = Math.round(base * SIDEBAR_SCALE);
      return h(React.Fragment, null,
        h('style', { key: 'bc-sidebar-css' }, SIDEBAR_CSS),
        coverImage(size, Math.max(4, Math.round(size * 0.28)) + 'px', 'center', 'bc-sidebar-mark'));
    }

    /**
     * Hero slot: larger, circular, floating with a soft blue glow. The owner's
     * `className` carries the surrounding geometry, so it wraps the whole mark.
     */
    function HeroMark(props) {
      const base = typeof props?.size === 'number' && props.size > 0 ? props.size : 64;
      const px = Math.round(base * HERO_SCALE);
      const className = 'bc-hero' + (props?.className ? ' ' + props.className : '');
      return h(React.Fragment, null,
        h('style', { key: 'bc-hero-css' }, HERO_CSS + PREVIEW_CSS),
        h('div', {
          className,
          style: {
            display: 'inline-block',
            lineHeight: 0,
            borderRadius: '50%',
            filter: 'drop-shadow(0 8px 26px rgba(91,155,255,.5))',
          },
        }, coverImage(px, '50%', 'center')),
      );
    }

    /**
     * Sidebar name slot: the brand name with the build version badge beneath it.
     * The version comes from the boot payload's `release` metadata, so it tracks
     * the running build instead of going stale. The owner's `brandName` span is
     * 24px tall — exactly the shipped 12px title plus 10px badge — so the title
     * stays at 12px rather than overflowing that fixed height.
     */
    const BRAND_NAME = '蓝色大肥鱼';

    function buildVersion() {
      try {
        const release = globalThis.__DSH_BOOT__ && globalThis.__DSH_BOOT__.release;
        if (release && typeof release.version === 'string' && release.version) {
          return release.commit ? release.version + '-' + release.commit : release.version;
        }
      } catch (unavailable) {
        // No boot payload: render the name on its own.
      }
      return '';
    }

    function BrandName() {
      const version = buildVersion();
      return h('span', {
        style: {
          display: 'inline-flex',
          flexDirection: 'column',
          flex: 'none',
          justifyContent: 'center',
          alignItems: 'flex-start',
          gap: '1px',
          height: '24px',
          whiteSpace: 'nowrap',
        },
      }, [
        h('span', {
          key: 'name',
          style: { letterSpacing: 0, fontSize: '12px', lineHeight: '13px' },
        }, BRAND_NAME),
        version === '' ? null : h('span', {
          key: 'version',
          style: {
            display: 'inline-flex',
            alignItems: 'center',
            height: '10px',
            padding: '0 3px',
            borderRadius: '2px',
            flex: 'none',
            color: 'var(--dsw-alias-label-primary-inverted)',
            background: 'var(--dsw-alias-label-primary)',
            fontFamily: 'var(--ds-font-family-code)',
            fontSize: '6px',
            fontWeight: 500,
            lineHeight: '10px',
            whiteSpace: 'nowrap',
          },
        }, version),
      ]);
    }

    /**
     * Each slot is declared by another package, so every registration waits.
     *
     * `priority: -1` is required, not cosmetic: these are `single` slots that the
     * shipped sidebar already fills at priority 0, and equal priority throws
     * "already has a registration at priority 0" instead of shadowing. The owner
     * documents that the lowest priority renders, so -1 deterministically wins
     * regardless of which package registers first.
     */
    const PRIORITY = -1;
    const REGISTRATIONS = [
      { name: 'sidebar.brand.mark', component: SidebarMark },
      { name: 'sidebar.brand.name', component: BrandName },
      { name: 'conversation.hero.brand.mark', component: HeroMark },
    ];

    return {
      inject: ['slots'],
      apply(ctx) {
        // These slots are declared as children of entries that can load after this
        // module. `inject` defers each registration until its slot is declared —
        // registering eagerly throws and fails the whole web boot.
        for (const { name, component } of REGISTRATIONS) {
          ctx.slots.inject(name, () => ctx.slots.register({ name, priority: PRIORITY }, component));
        }
      },
    };
  },
});
