# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  resources :applicants do
    patch :change_stage, on: :member
    resources :emails, only: %i[index new create show]
    get :resume, action: :show, controller: 'resumes'
  end

  resources :jobs

  devise_for :users,
             path: '',
             controllers: {
               registrations: 'users/registrations',
               sessions: 'users/sessions'
             },
             path_names: {
               sign_in: 'login',
               password: 'forgot',
               confirmation: 'confirm',
               sign_up: 'sign_up',
               sign_out: 'signout'
            }

  get 'dashboard/show'

  authenticated :user do
    root to: 'dashboard#show', as: :user_root
  end

  devise_scope :user do
    root to: 'devise/sessions#new'
  end
end
# rubocop:enable Metrics/BlockLength
