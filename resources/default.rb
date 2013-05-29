actions :fetch

attribute :jenkins_host,         :kind_of => String
attribute :jenkins_user,         :kind_of => String
attribute :jenkins_pass,         :kind_of => String
attribute :jenkins_project_name, :kind_of => String,  :name_attribute => true
attribute :build_type,           :kind_of => String
attribute :build_num,            :kind_of => String
attribute :target_dir,           :kind_of => String
attribute :target_file,          :kind_of => String
attribute :owner,                :kind_of => String
attribute :mode,                 :kind_of => String
