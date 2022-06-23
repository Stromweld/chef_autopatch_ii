# InSpec test for recipe xe_aws_cloudwatch_agent::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

if os.windows?
  describe windows_task('autopatch') do
    it { should be_enabled }
  end
else
  describe crontab(path: '/etc/cron.d/autopatch') do
    its('commands') { should include '/usr/local/sbin/autopatch 2>&1' }
  end
end
