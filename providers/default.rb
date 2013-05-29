
# TODO: handle multiple artifacts

require 'uri'

action :fetch do
  ensure_jenkins_gem_installed
  artifact_uris = get_artifact_uri()
  
  artifact_uris.each do |artifact_uri|
    #target = "#{new_resource.target_dir}/#{new_resource.target_file}"
	target = artifact_uri[:abs]
    uri = add_auth_to_uri(artifact_uri[:abs],
                          new_resource.jenkins_user,
                          new_resource.jenkins_pass)
    Chef::Log.info("fetching #{artifact_uri[:rel]} to #{target}")

    remote_file "#{new_resource.target_dir}/"+artifact_uri[:rel] do
      source uri
      owner  new_resource.owner
      mode   new_resource.mode
    end
    new_resource.updated_by_last_action(true)
  end

end

private

def get_artifact_uri()
  build_types = ["lastBuild",
                 "lastCompletedBuild",
                 "lastFailedBuild",
                 "lastStableBuild",
                 "lastSuccessfulBuild",
                 "lastUnstableBuild",
                 "lastUnsuccessfulBuild",
                ]

  api = Jenkins::Api
  # TODO: detect if no user/pass and don't do the auth stuffs
  api.setup_base_url({
                       :host     => new_resource.jenkins_host,
                       :username => new_resource.jenkins_user,
                       :password => new_resource.jenkins_pass
                     })
  job = api.job(new_resource.jenkins_project_name)
  if build_types.include?(new_resource.build_type)
    known_build_type(api, job)
  elsif new_resource.build_num.to_i() > 0
    build_number(api, new_resource.build_num)
  else
    # TODO: how to log and throw in chef?
    raise "jenkins build number or type error"
  end
end

def add_auth_to_uri(uri, user, pass)
  u = URI.parse(uri)
  u.userinfo = "#{user}:#{pass}"
  u.to_s()
end

def known_build_type(api, job)
  named_build = job.parsed_response["#{new_resource.build_type}"]
  num = named_build['number']
  build_number(api, num)
end

def build_number(api, num)
  # TODO: better handling on builds with no artifacts in json
  #       like collecterl-dev #12
  Chef::Log.info("Jenkins project: #{new_resource.jenkins_project_name}")
  Chef::Log.info("Jenkins build  : #{num}")
  if true || new_build?(num)
    Chef::Log.info("new Jenkins build, so proceeding with deploy.")
    build = api.build_details(new_resource.jenkins_project_name, num)
    # TODO: do this saving thing after successful remote_file above?
    node.set[:jenkins_artifact][new_resource.jenkins_project_name][:build] = num
    node.save
	artifacts = []
	build['artifacts'].each do |artifact|
		#"#{build['url']}artifact/#{build['artifacts'][0]['relativePath']}"
		artifacts << {:rel=>artifact['relativePath'], :abs=>"#{build['url']}artifact/#{artifact['relativePath']}"}
	end
	artifacts
  else
    nil
  end
end

def new_build?(new)
  begin
    cur = node[:jenkins_artifact][new_resource.jenkins_project_name][:build]
  rescue
    cur = nil
  end
  Chef::Log.info("Old build num  : #{cur}")
  new != cur
end

def ensure_jenkins_gem_installed
  begin
    require 'jenkins'
  rescue LoadError
    Chef::Log.info("Missing gem 'jenkins'... installing now.")
    gem_package "jenkins" do
      action :nothing
    end.run_action(:install)
    Gem.clear_paths
    require 'jenkins'
  end
end
