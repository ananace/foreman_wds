Rails.application.routes.draw do
  scope '/foreman_wds' do
    constraints(id: %r{[^\/]+}) do
      resources :wds_servers do
        collection do
          get 'auto_complete_search'
          post 'test_connection'
        end
        resources :wds_images, except: %i[show]
      end
    end
  end

  constraints(id: /[^\/]+/) do
    resources :hosts do
      collection do
        post 'wds_server_selected'
        post 'wds_image_selected'
      end
    end
  end
end
