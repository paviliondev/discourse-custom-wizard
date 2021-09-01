//= require_tree_discourse discourse/app/lib

//= require discourse/app/mixins/singleton
//= require discourse/app/mixins/upload
//= require discourse/app/mixins/composer-upload
//= require discourse/app/mixins/textarea-text-manipulation

//= require discourse/app/adapters/rest

//= require message-bus

//= require_tree_discourse discourse/app/models

//= require discourse/app/helpers/category-link
//= require discourse/app/helpers/user-avatar
//= require discourse/app/helpers/format-username
//= require discourse/app/helpers/share-url
//= require discourse/app/helpers/decorate-username-selector
//= require discourse-common/addon/helpers/component-for-collection
//= require discourse-common/addon/helpers/component-for-row
//= require discourse-common/addon/lib/raw-templates
//= require discourse/app/helpers/discourse-tag

//= require discourse/app/services/app-events
//= require discourse/app/services/emoji-store

//= require discourse/app/components/user-selector
//= require discourse/app/components/conditional-loading-spinner
//= require discourse/app/components/d-button
//= require discourse/app/components/composer-editor
//= require discourse/app/components/d-editor
//= require discourse/app/components/input-tip
//= require discourse/app/components/emoji-picker
//= require discourse/app/components/input-tip
//= require discourse/app/components/date-picker
//= require discourse/app/components/time-input
//= require discourse/app/components/date-input
//= require discourse/app/components/date-time-input
//= require discourse/app/components/text-field
//= require discourse/app/components/d-textarea

//= require discourse/app/templates/components/conditional-loading-spinner
//= require discourse/app/templates/components/d-button
//= require discourse/app/templates/components/d-editor
//= require discourse/app/templates/components/date-picker
//= require discourse/app/templates/components/date-input
//= require discourse/app/templates/components/time-input
//= require discourse/app/templates/components/date-time-input
//= require discourse/app/templates/components/emoji-picker
//= require discourse/app/templates/components/popup-input-tip
//= require discourse/app/templates/category-tag-autocomplete
//= require discourse/app/templates/emoji-selector-autocomplete
//= require discourse/app/templates/user-selector-autocomplete

//= require discourse/app/initializers/jquery-plugins
//= require discourse/app/pre-initializers/sniff-capabilities

//= require ember-addons/decorator-alias
//= require ember-addons/macro-alias
//= require ember-addons/fmt
//= require polyfills

//= require markdown-it-bundle
//= require lodash.js
//= require mousetrap.js
//= require template_include.js
//= require caret_position.js
//= require popper.js
//= require bootstrap-modal.js
//= require bootbox.js
//= require discourse-shims

//= require ./wizard/custom-wizard
//= require_tree ./wizard/components
//= require_tree ./wizard/controllers
//= require_tree ./wizard/helpers
//= require_tree ./wizard/initializers
//= require_tree ./wizard/lib
//= require_tree ./wizard/models
//= require_tree ./wizard/routes
//= require_tree ./wizard/templates
