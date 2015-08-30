{CompositeDisposable} = require 'atom'
{SpacePenDSL, EventsDelegation} = require 'atom-utils'

capitalize = (s) -> s.replace /^./, (m) -> m.toUpperCase()

class ColorProjectElement extends HTMLElement
  SpacePenDSL.includeInto(this)
  EventsDelegation.includeInto(this)

  @content: ->
    arrayField = (name, label) =>
      settingName = "pigments.#{name}"

      @div class: 'control-group array', =>
        @div class: 'controls', =>
          @label class: 'control-label', =>
            @span class: 'setting-title', label

          @div class: 'control-wrapper', =>
            @tag 'atom-text-editor', mini: true, outlet: name, type: 'array', property: name
            @div class: 'setting-description', "Package config: #{atom.config.get(settingName).join(', ')}"

    booleanField = (name, label, description) =>
      @div class: 'control-group boolean', =>
        @div class: 'controls', =>
          @input type: 'checkbox', id: "pigments-#{name}", outlet: name
          @label class: 'control-label', for: "pigments-#{name}", =>
            @span class: 'setting-title', label

          if description?
            @div class: 'setting-description', =>
              @raw description

    @section class: 'settings-view pane-item', =>
      @div class: 'settings-wrapper', =>
        @div class: 'header', =>
          @div class: 'logo', =>
            @img src: 'atom://pigments/resources/logo.svg', width: 140, height: 35

          @p class: 'setting-description', """
          These settings apply on the current project only and are complementary
          to the package settings.
          """

        @div class: 'fields', =>
          themes = atom.themes.getActiveThemeNames()
          arrayField('sourceNames', 'Source Names')
          arrayField('ignoredNames', 'Ignored Names')
          arrayField('ignoredScopes', 'Ignored Scopes')

          booleanField('includeThemes', 'Include Atom Themes Stylesheets', """
          The paths to <code>#{themes[0]}</code> and <code>#{themes[1]}</code>
          stylesheets will be automatically added to the source names and their
          variables will be made available when evaluating or completing
          a color.
          """)

  createdCallback: ->
    @subscriptions = new CompositeDisposable

  setModel: (@project) ->
    @initializeBindings()

  initializeBindings: ->
    grammar = atom.grammars.grammarForScopeName('source.js.regexp')
    @ignoredScopes.getModel().setGrammar(grammar)

    @initializeTextEditor('sourceNames')
    @initializeTextEditor('ignoredNames')
    @initializeTextEditor('ignoredScopes')
    @initializeCheckbox('includeThemes')

  initializeTextEditor: (name) ->
    capitalizedName = capitalize name
    editor = @[name].getModel()

    editor.setText((@project[name] ? []).join(', '))

    @subscriptions.add editor.onDidStopChanging =>
      array = editor.getText().split(/\s*,\s*/g).filter (s) -> s.length > 0
      @project["set#{capitalizedName}"](array)

  initializeCheckbox: (name) ->
    capitalizedName = capitalize name
    checkbox = @[name]
    checkbox.checked = @project[name]

    @subscriptions.add @subscribeTo checkbox, change: =>
      @project["set#{capitalizedName}"](checkbox.checked)

  getTitle: -> 'Pigments Settings'

  getURI: -> 'pigments://settings'

  getIconName: -> "pigments"

module.exports = ColorProjectElement =
document.registerElement 'pigments-color-project', {
  prototype: ColorProjectElement.prototype
}

ColorProjectElement.registerViewProvider = (modelClass) ->
  atom.views.addViewProvider modelClass, (model) ->
    element = new ColorProjectElement
    element.setModel(model)
    element