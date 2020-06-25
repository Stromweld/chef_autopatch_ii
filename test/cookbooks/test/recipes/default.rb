# Test
# attribute override
node.default['autopatch_ii']['auto_reboot_enabled'] = false

# runlist
include_recipe 'autopatch_ii'
include_recipe 'autopatch_ii::firstrun_patches'
