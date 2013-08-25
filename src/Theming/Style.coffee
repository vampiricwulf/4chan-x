Style =
  init: ->
    theme = Themes[Conf['theme']] or Themes['Yotsuba B']
    Style.svg = $.el 'div',
      id: 'svg_filters'

    items = [
      ['layoutCSS',    Style.layout,       'layout']
      ['themeCSS',     Style.theme(theme), 'theme']
      ['emojiCSS',     Emoji.css(),        'emoji']
      ['dynamicCSS',   Style.dynamic(),    'dynamic']
      ['paddingSheet', "",                 'padding']
      ['mascot',       "",                 'mascotSheet']
    ]

    i = 0
    while item = items[i++]
      Style[item[0]] = $.addStyle item[1], item[2]

    # Non-customizable
    $.addStyle JSColor.css(), 'jsColor'

    $.asap (-> d.head), Style.observe

    $.asap (-> d.body), @asapInit
    $.on window, "resize", Style.padding
    $.ready @readyInit

  asapInit: ->
    <% if (type === 'crx') { %>
    $.addClass doc, 'blink'
    <% } else { %>
    $.addClass doc, 'gecko'
    <% } %>
    $.addClass doc, 'fourchan-x'
    $.addClass doc, 'appchan-x'
    $.addClass doc, g.VIEW

    $.add d.body, Style.svg

    for title, cat of Config.style
      for name, setting of cat
        continue if !Conf[name] or setting[2] is 'text'
        hyphenated = "#{name}#{if setting[2] then " #{Conf[name]}" else ""}".toLowerCase().replace(/^4/, 'four').replace /\s+/g, '-'
        $.addClass doc, hyphenated

    if g.VIEW is 'index'
      $.asap (-> $ '.mPagelist'), ->
        Style.pages 'prev', '<'
        Style.pages 'next', '>'

  pages: (name, text) ->
    el = $ ".pagelist > .#{name}"
    elA = $.el 'a',
      textContent: text

    if (action = el.firstElementChild).nodeName is 'FORM'
      elA.href = 'javascript:;'
      $.on elA, 'click', ->
        action.firstElementChild.click()

    $.add el, elA

  readyInit: ->
    Style.padding()
    Style.iconPositions()
    if exLink = $ "#navtopright .exlinksOptionsLink", d.body
      $.on exLink, "click", ->
        setTimeout Rice.nodes, 100
    
    if g.VIEW is 'catalog'
      unless $.id('threads').children.length
        # Race conditions
        setTimeout (-> $.globalEval 'fourcat.init(); fourcat.loadCatalog(catalog);'), 1000

  observe: ->
    if window.MutationObserver
      Style.observer = new MutationObserver onMutationObserver = Style.wrapper
      Style.observer.observe d.head,
        childList: true
        subtree: true
    else
      $.on d.head, 'DOMNodeInserted', Style.wrapper

  wrapper: ->
    first = {addedNodes: d.head.children}
    Style.remStyle(first)

    if d.readyState is 'complete'
      if Style.observer
        Style.observer.disconnect()
      else
        $.off d, 'DOMNodeInserted', Style.wrapper

  remStyle: ({addedNodes}) ->
    i = addedNodes.length
    while i--
      node = addedNodes[i]

      continue if node.nodeName is 'STYLE' and node.id or
        !['LINK', 'STYLE'].contains(node.nodeName) or
        node.rel and ((!/stylesheet/.test(node.rel) or /flags.*\.css$/.test(href = node.href) or href[..3] is 'data')) or
        /\.typeset/.test node.textContent
      $.rm node
    return

  matrix: (foreground, background) ->
    fgHex = Style.colorToHex(foreground) or "ffffff"

    fg = {
      r: parseInt(fgHex.substr(0, 2), 16) / 255
      g: parseInt(fgHex.substr(2, 2), 16) / 255
      b: parseInt(fgHex.substr(4, 2), 16) / 255
    }

    if background
      bgHex = Style.colorToHex(background) or "000000"

      bg = {
        r: parseInt(bgHex.substr(0, 2), 16) / 255
        g: parseInt(bgHex.substr(2, 2), 16) / 255
        b: parseInt(bgHex.substr(4, 2), 16) / 255
      }

      return [fg, bg]

    [fg]

  filter: ([fg, bg]) ->
    "#{bg.r} #{-fg.r} 0 0 #{fg.r} #{bg.g} #{-fg.g} 0 0 #{fg.g} #{bg.b} #{-fg.b} 0 0 #{fg.b}"

  silhouette: ([fg]) ->
    "0 0 0 0 #{fg.r} 0 0 0 0 #{fg.g} 0 0 0 0 #{fg.b}"

  layout: """<%=
    grunt.file.read('src/General/css/layout.css').replace(/\s+/g, ' ').trim()
    + ' ' +
    grunt.file.read('src/General/css/font-awesome.css').replace(/\s+/g, ' ').replace(/\\/g, '\\\\').trim()
  %>"""

  dynamic: ->
    sidebarLocation = if Conf["Sidebar Location"] is "left"
      ["left",  "right"]
    else
      ["right", "left" ]

    if Conf['editMode'] is "theme"
      editSpace = {}
      editSpace[sidebarLocation[1]] = 300
      editSpace[sidebarLocation[0]] = 0
    else
      editSpace =
        left:   0
        right:  0

    """<%= grunt.file.read('src/General/css/dynamic.css').replace(/\s+/g, ' ').trim() %>"""

  theme: (theme) ->
    bgColor = new Style.color(Style.colorToHex(backgroundC = theme["Background Color"]) or 'aaaaaa')
    replybg = new Style.color Style.colorToHex theme["Reply Background"]
    replyRGB = "rgb(#{replybg.shiftRGB parseInt(Conf['Silhouette Contrast'], 10), true})"

    Style.lightTheme = bgColor.isLight()

    Style.svg.innerHTML = """
<svg xmlns='http://www.w3.org/2000/svg' height=0><filter id='captcha-filter' color-interpolation-filters='sRGB'><feColorMatrix values='#{Style.filter Style.matrix theme["Text"], theme["Input Background"]} 0 0 0 1 0' /></filter></svg>
<svg xmlns='http://www.w3.org/2000/svg' height=0><filter id='mascot-filter' color-interpolation-filters='sRGB'><feColorMatrix values='#{Style.silhouette Style.matrix replyRGB} 0 0 0 1 0' /></filter></svg>
<svg xmlns='http://www.w3.org/2000/svg' height=0><filter id="grayscale"><feColorMatrix id="color" type="saturate" values="0" /></filter></svg>
<svg xmlns='http://www.w3.org/2000/svg' height=0><filter id="icons-filter" color-interpolation-filters='sRGB'><feColorMatrix values='-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0' /></filter></svg>
    """

    """<%= grunt.file.read('src/General/css/theme.css').replace(/\s+/g, ' ').trim() %>""" + <%= grunt.file.read('src/General/css/themeoptions.css').replace(/\s+/g, ' ').trim() %>

  iconPositions: ->
    # Slideout Navigation
    slideNav = $.el 'span',
      id: 'so-nav'
      innerHTML: '<i class=a-icon></a>'
    $.add slideNav, $.id('boardNavDesktopFoot')
    Header.addShortcut slideNav, true if Conf['Slideout Navigation'] isnt 'hide'

    # Announcements
    if Conf['Announcements'] is 'slideout'
      if (psa = $.id '#globalMessage') and !psa.hidden
        psaIcon = $.el 'i',
          id: 'so-psa'
          innerHTML: '<i class=a-icon></a>'
        $.add psa, psaIcon
        Header.addShortcut psaIcon, true

    if g.VIEW is 'thread'
      el = $('body > div.navLinks > a')
      el.textContent = ''
      el.id = 'returnIcon'
      el.className = 'a-icon'
      Header.addShortcut el, true

  padding: ->
    navHeight  = Header.bar.offsetHeight
    pageHeight = ($ '.pagelist', d.body)?.offsetHeight
    css = """<%= grunt.file.read('src/General/css/padding.nav.css').replace(/\s+/g, ' ').trim() %>"""

    if pageHeight
      css += """<%= grunt.file.read('src/General/css/padding.pages.css').replace(/\s+/g, ' ').trim() %>"""

    Style.paddingSheet.textContent = css

  color: (hex) ->
    @hex = "#" + hex

    @calc_rgb = (hex) ->
      hex = parseInt hex, 16
      [ # 0xRRGGBB to [R, G, B]
        (hex >> 16) & 0xFF
        (hex >> 8) & 0xFF
        hex & 0xFF
      ]

    @private_rgb = @calc_rgb(hex)

    @rgb = @private_rgb.join ","

    @isLight = ->
      rgb = @private_rgb
      return (rgb[0] + rgb[1] + rgb[2]) >= 400

    @shiftRGB = (shift, smart) ->
      minmax = (base) ->
        Math.min Math.max(base, 0), 255
      rgb = @private_rgb.slice 0
      shift = if smart
        (
          if @isLight rgb
            -1
          else
            1
        ) * Math.abs shift
      else
        shift

      return [
        minmax rgb[0] + shift
        minmax rgb[1] + shift
        minmax rgb[2] + shift
      ].join ","

    @hover = @shiftRGB 16, true

  colorToHex: (color) ->
    if color.substr(0, 1) is '#'
      return color.slice 1, color.length

    if digits = color.match /(.*?)rgba?\((\d+), ?(\d+), ?(\d+)(.*?)\)/
      # [R, G, B] to 0xRRGGBB
      hex = (
        (parseInt(digits[2], 10) << 16) |
        (parseInt(digits[3], 10) << 8)  |
        (parseInt(digits[4], 10))
      ).toString 16

      while hex.length < 6
        hex = "0#{hex}"

      hex

    else
      false