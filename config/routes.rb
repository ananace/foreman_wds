Rails.application.routes.draw do
  scope '/foreman_wds' do
    resources :wds_servers, only: %i[index show] do
      collection do
        get 'auto_complete_search'
      end
    end
  end
end
