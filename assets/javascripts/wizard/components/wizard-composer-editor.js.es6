import ComposerEditor from 'discourse/components/composer-editor';
import { default as computed, on } from 'discourse-common/utils/decorators';
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { throttle } from "@ember/runloop";
import { scheduleOnce } from "@ember/runloop";
import { safariHacksDisabled } from "discourse/lib/utilities";

export default ComposerEditor.extend({
  classNameBindings: ['fieldClass'],
  allowUpload: false,
  showLink: false,
  topic: null,
  showToolbar: true,
  focusTarget: "reply",
  canWhisper: false,
  lastValidatedAt: 'lastValidatedAt',
  uploadIcon: "upload",
  popupMenuOptions: [],
  draftStatus: 'null',
  
  @on("didInsertElement")
  _composerEditorInit() {
    const $input = $(this.element.querySelector(".d-editor-input"));
    const $preview = $(this.element.querySelector(".d-editor-preview-wrapper"));
    
    if (this.siteSettings.enable_mentions) {
      $input.autocomplete({
        template: findRawTemplate("user-selector-autocomplete"),
        dataSource: term => this.userSearchTerm.call(this, term),
        key: "@",
        transformComplete: v => v.username || v.name,
        afterComplete() {
          scheduleOnce("afterRender", () => $input.blur().focus());
        }
      });
    }

    if (this._enableAdvancedEditorPreviewSync()) {
      this._initInputPreviewSync($input, $preview);
    } else {
      $input.on("scroll", () =>
        throttle(this, this._syncEditorAndPreviewScroll, $input, $preview, 20)
      );
    }

    this._bindUploadTarget();
  },
    
  _bindUploadTarget() {
  },
  
  _unbindUploadTarget() {
  },
  
  actions: {
    extraButtons(toolbar) {
      if (this.allowUpload && this.uploadIcon && !this.site.mobileView) {
        toolbar.addButton({
          id: "upload",
          group: "insertions",
          icon: this.uploadIcon,
          title: "upload",
          sendAction: this.showUploadModal
        });
      }
    }
  }
})