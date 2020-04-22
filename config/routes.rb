CustomWizard::Engine.routes.draw do
  get ':wizard_id' => 'wizard#index'
  put ':wizard_id/skip' => 'wizard#skip'
  get ':wizard_id/steps' => 'wizard#index'
  get ':wizard_id/steps/:step_id' => 'wizard#index'
  put ':wizard_id/steps/:step_id' => 'steps#update'
end

Discourse::Application.routes.append do
  mount ::CustomWizard::Engine, at: 'w'
  post 'wizard/authorization/callback' => "custom_wizard/authorization#callback"

  scope module: 'custom_wizard', constraints: AdminConstraint.new do
    get 'admin/wizards' => 'admin#index'
    
    get 'admin/wizards/wizard' => 'admin_wizard#index'
    get 'admin/wizards/wizard/create' => 'admin#index'
    get 'admin/wizards/wizard/:wizard_id' => 'admin_wizard#show'
    put 'admin/wizards/wizard/:wizard_id' => 'admin_wizard#save'
    delete 'admin/wizards/wizard/:wizard_id' => 'admin_wizard#remove'
    
    get 'admin/wizards/submissions' => 'admin_submissions#index'
    get 'admin/wizards/submissions/:wizard_id' => 'admin_submissions#show'
    get 'admin/wizards/submissions/:wizard_id/download' => 'admin_submissions#download'
  
    get 'admin/wizards/api' => 'admin_api#list'
    get 'admin/wizards/api/:name' => 'admin_api#find'
    put 'admin/wizards/api/:name' => 'admin_api#save'
    delete 'admin/wizards/api/:name' => 'admin_api#remove'
    delete 'admin/wizards/api/:name/logs' => 'admin_api#clearlogs'
    get 'admin/wizards/api/:name/redirect' => 'admin_api#redirect'
    get 'admin/wizards/api/:name/authorize' => 'admin_api#authorize'
    
    get 'admin/wizards/logs' => 'admin_logs#index'
    
    get 'admin/wizards/transfer' => 'transfer#index'
    get 'admin/wizards/transfer/export' => 'transfer#export'
    post 'admin/wizards/transfer/import' => 'transfer#import'
  end
end