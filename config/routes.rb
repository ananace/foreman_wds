Rails.application.routes.draw do
  scope '/foreman_wds' do
    constraints(id: %r{[^\/]+}) do
      resources :wds_servers do
        collection do
          get 'auto_complete_search'
          post 'test_connection'
        end
        member do
          post 'refresh_cache'
          get 'wds_clients'
          get 'wds_images'
        end
      end
    end
  end

  constraints(id: %r{[^\/]+}) do
    resources :hosts, only: [] do
      collection do
        post 'wds_server_selected'
        post 'wds_image_selected'
      end
    end
    resources :discovered_hosts, only: [] do
      collection do
        post 'wds_server_selected'
        post 'wds_image_selected'
      end
    end
  end
end
