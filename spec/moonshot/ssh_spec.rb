describe 'Moonshot SSH features' do
  let(:ssh_target_selector) { instance_double(Moonshot::SSHTargetSelector) }
  let(:disable_strict_hostkey_check) { false }

  subject do
    c = Moonshot::ControllerConfig.new
    c.app_name = 'MyApp'
    c.environment_name = 'prod'
    c.ssh_config.ssh_user = 'joeuser'
    c.ssh_config.ssh_identity_file = '/Users/joeuser/.ssh/thegoods.key'
    c.ssh_disable_strict_hostkey_check = disable_strict_hostkey_check
    c.ssh_command = 'cat /etc/passwd'

    Moonshot::Controller.new(c)
  end

  before do
    allow(Moonshot::SSHTargetSelector).to receive(:new)
      .and_return(ssh_target_selector)
    allow(ssh_target_selector).to receive(:choose!)
      .and_return('i-04683a82f2dddcc04')
    allow_any_instance_of(Moonshot::SSHCommandBuilder).to receive(:instance_ip)
      .and_return('123.123.123.123')
  end

  describe 'Moonshot::Controller#ssh' do
    context 'normally' do
      it 'should execute an ssh command with proper parameters' do
        expect_any_instance_of(Moonshot::SSHCommandBuilder).to receive(:instance_ip).twice
        expect(subject).to receive(:exec)
          .with('ssh -t -i /Users/joeuser/.ssh/thegoods.key -l joeuser 123.123.123.123 cat\ /etc/passwd') # rubocop:disable LineLength
        expect { subject.ssh }
          .to output("Opening SSH connection to i-04683a82f2dddcc04 (123.123.123.123)...\n")
          .to_stderr
      end
    end

    context 'when an instance id is given' do
      subject do
        c = super()
        c.config.ssh_instance = 'i-012012012012012'
        c
      end

      it 'should execute an ssh command with proper parameters' do
        expect_any_instance_of(Moonshot::SSHCommandBuilder).to receive(:instance_ip).exactly(2)
        expect(subject).to receive(:exec)
          .with('ssh -t -i /Users/joeuser/.ssh/thegoods.key -l joeuser 123.123.123.123 cat\ /etc/passwd') # rubocop:disable LineLength
        expect { subject.ssh }
          .to output("Opening SSH connection to i-012012012012012 (123.123.123.123)...\n").to_stderr
      end
    end

    context 'strict hostkey check' do
      context 'when option is to disable' do
        let(:disable_strict_hostkey_check) { true }

        it 'should execute an ssh command with proper parameters' do
          expect(subject).to receive(:exec)
            .with('ssh -t -i /Users/joeuser/.ssh/thegoods.key -l joeuser '\
                  '-oStrictHostKeyChecking=no 123.123.123.123 cat\ ' \
                  '/etc/passwd')
          subject.ssh
        end
      end

      context 'when option is not to disable' do
        let(:disable_strict_hostkey_check) { false }

        it 'should execute an ssh command with proper parameters' do
          expect(subject).to receive(:exec)
            .with('ssh -t -i /Users/joeuser/.ssh/thegoods.key -l joeuser '\
                  '123.123.123.123 cat\ /etc/passwd')
          subject.ssh
        end
      end
    end
  end
end
