# app/workers/hello_worker.rb
class HelloWorker
  include Sidekiq::Worker
  def perform(name)
    Rails.logger.info "Hello, #{name} from Sidekiq!"
  end
end
