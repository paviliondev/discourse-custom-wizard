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
    get 'admin/wizards/field-types' => 'admin#field_types'
    get 'admin/wizards/custom' => 'admin#index'
    get 'admin/wizards/custom/new' => 'admin#index'
    get 'admin/wizards/custom/all' => 'admin#custom_wizards'
    get 'admin/wizards/custom/:wizard_id' => 'admin#find_wizard'
    get 'admin/wizards/custom/:wizard_id' => 'admin#find_wizard'
    put 'admin/wizards/custom/save' => 'admin#save'
    delete 'admin/wizards/custom/remove' => 'admin#remove'
    get 'admin/wizards/submissions' => 'admin#index'
    get 'admin/wizards/submissions/:wizard_id' => 'admin#submissions'
    get 'admin/wizards/submissions/:wizard_id/download' => 'admin#download_submissions'
    get 'admin/wizards/apis' => 'api#list'
    get 'admin/wizards/apis/new' => 'api#index'
    get 'admin/wizards/apis/:name' => 'api#find'
    put 'admin/wizards/apis/:name' => 'api#save'
    delete 'admin/wizards/apis/:name' => 'api#remove'
    delete 'admin/wizards/apis/logs/:name' => 'api#clearlogs'
    get 'admin/wizards/apis/:name/redirect' => 'api#redirect'
    get 'admin/wizards/apis/:name/authorize' => 'api#authorize'
    get 'admin/wizards/transfer' => 'transfer#index'
    get 'admin/wizards/transfer/export' => 'transfer#export'
    post 'admin/wizards/transfer/import' => 'transfer#import'
  end
end