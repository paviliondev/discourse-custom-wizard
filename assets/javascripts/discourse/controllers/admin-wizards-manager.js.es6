import Controller from "@ember/controller";
import {
  default as discourseComputed,
  observes
} from 'discourse-common/utils/decorators';
import { empty } from "@ember/object/computed";
import CustomWizardManager from '../models/custom-wizard-manager';
import { A } from "@ember/array";
import I18n from "I18n";
import { underscore } from "@ember/string";

export default Controller.extend({
  messageUrl: 'https://thepavilion.io/t/3652',
  messageKey: 'info',
  messageIcon: 'info-circle',
  messageClass: 'info',
  importDisabled: empty('file'),
  exportWizards: A(),
  destroyWizards: A(),
  exportDisabled: empty('exportWizards'),
  destoryDisabled: empty('destroyWizards'),

  setMessage(type, key, opts={}, items=[]) {
    this.setProperties({
      messageKey: key,
      messageOpts: opts,
      messageType: type,
      messageItems: items
    });
    setTimeout(() => {
      this.setProperties({
        messageKey: 'info',
        messageOpts: null,
        messageType: null,
        messageItems: null
      })
    }, 10000);
  },
  
  buildWizardLink(wizard) {
    let html = `<a href='/admin/wizards/wizard/${wizard.id}'>${wizard.name}</a>`;
    html += `<span class='action'>${I18n.t('admin.wizard.manager.imported')}</span>`;
    return {
      icon: 'check-circle',
      html
    };
  },
  
  buildDestroyedItem(destroyed) {
    let html = `<span data-wizard-id="${destroyed.id}">${destroyed.name}</span>`;
    html += `<span class='action'>${I18n.t('admin.wizard.manager.destroyed')}</span>`;
    return {
      icon: 'check-circle',
      html
    };
  },
  
  buildFailureItem(failure) {
    return {
      icon: 'times-circle',
      html: `${failure.id}: ${failure.messages}`
    };
  },
  
  clearFile() {
    this.setProperties({
      file: null,
      filename: null
    });
    $('#file-upload').val('');
  },
  
  @observes('importing', 'destroying')
  setLoadingMessages() {
    if (this.importing) {
      this.setMessage("loading", "importing");
    }
    if (this.destroying) {
      this.setMessage("loading", "destroying");
    }
  },

  actions: {
    upload() {
      $('#file-upload').click();
    },
    
    clearFile() {
      this.clearFile();
    },
    
    setFile(event) {
      let maxFileSize = 512 * 1024;
      const file = event.target.files[0];

      if (file === undefined) {
        this.set('file', null);
        return;
      }
      
      if (maxFileSize < file.size) {
        this.setMessage("error", "file_size_error");
        this.set("file", null);
        $('#file-upload').val('');
      } else {
        this.setProperties({
          file,
          filename: file.name
        });
      }
    },
    
    selectWizard(event) {
      const type = event.target.classList.contains('export') ? 'export' : 'destroy';
      const wizards = this.get(`${type}Wizards`);
      const checked = event.target.checked;
      
      let wizardId = event.target.closest('tr').getAttribute('data-wizard-id');
      
      if (wizardId) {
        wizardId = underscore(wizardId);
      } else {
        return false;
      }
      
      if (checked) {
        wizards.addObject(wizardId);
      } else {
        wizards.removeObject(wizardId);
      }
    },

    import() {
      const file = this.get('file');
      
      if (!file) {
        this.setMessage("error", 'no_file');
        return;
      }
      
      let $formData = new FormData();
      $formData.append('file', file);
      
      this.set('importing', true);
      this.setMessage("loading", "importing");
      
      CustomWizardManager.import($formData).then(result => {
        if (result.error) {
          this.setMessage("error", "server_error", {
            message: result.error
          });
        } else {
          this.setMessage("success", "import_complete", {},
            result.imported.map(imported => {
              return this.buildWizardLink(imported);
            }).concat(
              result.failures.map(failure => {
                return this.buildFailureItem(failure);
              })
            )
          );
          
          if (result.imported.length) {
            this.get('wizards').addObjects(result.imported);
          }
        }
        this.clearFile();
      }).finally(() => {
        this.set('importing', false);
      });
    },

    export() {
      const exportWizards = this.get('exportWizards');

      if (!exportWizards.length) {
        this.setMessage("error", 'none_selected');
      } else {
        CustomWizardManager.export(exportWizards);
        exportWizards.clear();
        $('input.export').prop("checked", false);
      }
    },
    
    destroy() {
      const destroyWizards = this.get('destroyWizards');

      if (!destroyWizards.length) {
        this.setMessage("error", 'none_selected');
      } else {
        this.set('destroying', true);
        
        CustomWizardManager.destroy(destroyWizards).then((result) => {
          if (result.error) {
            this.setMessage("error", "server_error", {
              message: result.error
            });
          } else {
            this.setMessage("success", "destroy_complete", {},
              result.destroyed.map(destroyed => {
                return this.buildDestroyedItem(destroyed);
              }).concat(
                result.failures.map(failure => {
                  return this.buildFailureItem(failure);
                })
              )
            );
            
            if (result.destroyed.length) {
              const destroyedIds = result.destroyed.map(d => d.id);
              const destroyWizards = this.get('destroyWizards');
              const wizards = this.get('wizards');
              
              wizards.removeObjects(
                wizards.filter(w => {
                  return destroyedIds.includes(w.id);
                })
              );
                            
              destroyWizards.removeObjects(destroyedIds);
            }
          }
        }).finally(() => {
          this.set('destroying', false);
        });
      }
    }
  }
});
