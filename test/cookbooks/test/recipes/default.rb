# Test
# attribute override
node.default['autopatch_ii']['auto_reboot_enabled'] = false
node.default['autopatch_ii']['email_notification_mode'] = ENV['TEST_KITCHEN'] ? 'none' : 'Always'

# runlist
include_recipe 'autopatch_ii'
include_recipe 'autopatch_ii::firstrun_patches'
