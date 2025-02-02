# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::Knative do
  let(:knative) { create(:clusters_applications_knative) }

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
    allow(ClusterConfigureIstioWorker).to receive(:perform_async)
  end

  include_examples 'cluster application core specs', :clusters_applications_knative
  include_examples 'cluster application status specs', :clusters_applications_knative
  include_examples 'cluster application helm specs', :clusters_applications_knative
  include_examples 'cluster application version specs', :clusters_applications_knative
  include_examples 'cluster application initial status specs'

  describe 'default values' do
    it { expect(subject.version).to eq(described_class::VERSION) }
  end

  describe 'when cloud run is enabled' do
    let(:cluster) { create(:cluster, :provided_by_gcp, :cloud_run_enabled) }
    let(:knative_cloud_run) { create(:clusters_applications_knative, cluster: cluster) }

    it { expect(knative_cloud_run).to be_not_installable }
  end

  describe 'when rbac is not enabled' do
    let(:cluster) { create(:cluster, :provided_by_gcp, :rbac_disabled) }
    let(:knative_no_rbac) { create(:clusters_applications_knative, cluster: cluster) }

    it { expect(knative_no_rbac).to be_not_installable }
  end

  describe 'make_installed with external_ip' do
    before do
      application.make_installed!
    end

    let(:application) { create(:clusters_applications_knative, :installing) }

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(Clusters::Applications::Knative::FETCH_IP_ADDRESS_DELAY, 'knative', application.id)
    end
  end

  describe 'configuring istio ingress gateway' do
    context 'after installed' do
      let(:application) { create(:clusters_applications_knative, :installing) }

      before do
        application.make_installed!
      end

      it 'schedules a ClusterConfigureIstioWorker' do
        expect(ClusterConfigureIstioWorker).to have_received(:perform_async).with(application.cluster_id)
      end
    end

    context 'after updated' do
      let(:application) { create(:clusters_applications_knative, :updating) }

      before do
        application.make_installed!
      end

      it 'schedules a ClusterConfigureIstioWorker' do
        expect(ClusterConfigureIstioWorker).to have_received(:perform_async).with(application.cluster_id)
      end
    end
  end

  describe '#can_uninstall?' do
    subject { knative.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#schedule_status_update with external_ip' do
    let(:application) { create(:clusters_applications_knative, :installed) }

    before do
      application.schedule_status_update
    end

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_async)
        .with('knative', application.id)
    end

    context 'when the application is not installed' do
      let(:application) { create(:clusters_applications_knative, :installing) }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_async)
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_knative, :installed, external_ip: '111.222.222.111') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end

    context 'when there is already an external_hostname' do
      let(:application) { create(:clusters_applications_knative, :installed, external_hostname: 'localhost.localdomain') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  shared_examples 'a command' do
    it 'is an instance of Helm::InstallCommand' do
      expect(subject).to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::InstallCommand)
    end

    it 'is initialized with knative arguments' do
      expect(subject.name).to eq('knative')
      expect(subject.chart).to eq('knative/knative')
      expect(subject.files).to eq(knative.files)
    end

    it 'does not install metrics for prometheus' do
      expect(subject.postinstall).to be_empty
    end
  end

  describe '#install_command' do
    subject { knative.install_command }

    it 'is initialized with latest version' do
      expect(subject.version).to eq('0.10.0')
    end

    it_behaves_like 'a command'
  end

  describe '#update_command' do
    let!(:current_installed_version) { knative.version = '0.1.0' }

    subject { knative.update_command }

    it 'is initialized with current version' do
      expect(subject.version).to eq(current_installed_version)
    end

    it_behaves_like 'a command'
  end

  describe '#uninstall_command' do
    subject { knative.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::DeleteCommand) }

    it "removes knative deployed services before uninstallation" do
      2.times do |i|
        cluster_project = create(:cluster_project, cluster: knative.cluster)

        create(:cluster_kubernetes_namespace,
          cluster: cluster_project.cluster,
          cluster_project: cluster_project,
          project: cluster_project.project,
          namespace: "namespace_#{i}")
      end

      remove_namespaced_services_script = [
        "kubectl delete ksvc --all -n #{knative.cluster.kubernetes_namespaces.first.namespace}",
        "kubectl delete ksvc --all -n #{knative.cluster.kubernetes_namespaces.second.namespace}"
      ]

      expect(subject.predelete).to match_array(remove_namespaced_services_script)
    end

    it "initializes command with all necessary postdelete script" do
      api_groups = YAML.safe_load(File.read(Rails.root.join(Clusters::Applications::Knative::API_GROUPS_PATH)))

      remove_knative_istio_leftovers_script = [
        "kubectl delete --ignore-not-found ns knative-serving",
        "kubectl delete --ignore-not-found ns knative-build"
      ]

      full_delete_commands_size = api_groups.size + remove_knative_istio_leftovers_script.size

      expect(subject.postdelete).to include(*remove_knative_istio_leftovers_script)
      expect(subject.postdelete.size).to eq(full_delete_commands_size)
      expect(subject.postdelete[2]).to include("kubectl api-resources -o name --api-group #{api_groups[0]} | xargs -r kubectl delete --ignore-not-found crd")
      expect(subject.postdelete[3]).to include("kubectl api-resources -o name --api-group #{api_groups[1]} | xargs -r kubectl delete --ignore-not-found crd")
    end
  end

  describe '#files' do
    let(:application) { knative }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes knative specific keys in the values.yaml file' do
      expect(values).to include('domain')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hostname) }
  end

  describe '#available_domains' do
    let!(:domain) { create(:pages_domain, :instance_serverless) }

    it 'returns all instance serverless domains' do
      expect(PagesDomain).to receive(:instance_serverless).and_call_original

      domains = subject.available_domains

      expect(domains.length).to eq(1)
      expect(domains).to include(domain)
    end
  end

  describe '#find_available_domain' do
    let!(:domain) { create(:pages_domain, :instance_serverless) }

    it 'returns the domain scoped to available domains' do
      expect(subject).to receive(:available_domains).and_call_original
      expect(subject.find_available_domain(domain.id)).to eq(domain)
    end
  end
end
