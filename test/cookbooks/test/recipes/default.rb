# Test
# attribute override
node.default['autopatch_ii']['auto_reboot_enabled'] = false
node.default['autopatch_ii']['email_notification_mode'] = 'none'
node.default['autopatch_ii']['updates_to_skip'] = %w(openssh-server openssh-client)

# runlist
include_recipe 'autopatch_ii'
include_recipe 'autopatch_ii::firstrun_patches'
