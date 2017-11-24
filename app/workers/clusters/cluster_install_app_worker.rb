module Clusters
  class ClusterInstallAppWorker
    include Sidekiq::Worker
    include ClusterQueue
    include Concerns::ClusterApplications

    def perform(app_name, app_id)
      find_application(app_name, app_id) do |app|
        Clusters::Applications::InstallService.new(app).execute
      end
    end
  end
end
