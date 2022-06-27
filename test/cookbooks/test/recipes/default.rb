# Test
# attribute override
node.default['autopatch_ii']['auto_reboot_enabled'] = false
node.default['autopatch_ii']['email_notification_mode'] = 'none'
node.default['autopatch_ii']['updates_to_skip'] = windows? ? '' : %w(mysql-server postgres-server)

# runlist
include_recipe 'autopatch_ii'
include_recipe 'autopatch_ii::firstrun_patches'
