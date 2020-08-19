name 'autopatch_ii'
maintainer 'Corey Hemminger'
maintainer_email 'hemminger@hotmail.com'
license 'Apache-2.0'
description 'Installs/Configures autopatch_ii'
version '1.3.1'
chef_version '>= 14.4'

issues_url 'https://github.com/Stromweld/autopatch_ii/issues'
source_url 'https://github.com/Stromweld/autopatch_ii'

%w(amazon centos fedora redhat scientific oracle debian ubuntu windows).each do |os|
  supports os
end

gem 'tzinfo'

depends 'logrotate'
