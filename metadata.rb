name 'autopatch_ii'
maintainer 'Corey Hemminger'
maintainer_email 'hemminger@hotmail.com'
license 'Apache-2.0'
description 'Installs/Configures autopatch_ii'
long_description 'Installs/Configures autopatch_ii'
version '1.0.3'
chef_version '>= 12.6' if respond_to?(:chef_version)

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
issues_url 'https://github.com/Stromweld/autopatch_ii/issues'

# The `source_url` points to the development reposiory for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
source_url 'https://github.com/Stromweld/autopatch_ii'

%w(amazon centos fedora redhat scientific oracle windows).each do |os|
  supports os
end

depends 'cron'
depends 'logrotate'
