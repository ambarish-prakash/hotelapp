# app/jobs/hello_job.rb
class HelloJob < ApplicationJob
  queue_as :default
  def perform(name)
    Rails.logger.info "Hello, #{name} from ActiveJob+Sidekiq!"
  end
end

