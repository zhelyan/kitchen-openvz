require 'spec_helper'

describe Kitchen::Driver::Openvz do

  before :each do
    @openvz = described_class.new
  end

  it 'should assign free ip' do
    ip = IPAddr.new('10.1.1.0/24')
    allocated_ips = %w(10.1.1.1 10.1.1.2 10.1.1.3 10.1.1.4) # mock `vzlist -o ip -H -a`
                                                            #return same
    allocated_ips2 = %w() # mock `vzlist -o ip -H -a`
    allocated =@openvz.allocate_ip(ip, allocated_ips)
    allocated2 =@openvz.allocate_ip(ip, allocated_ips2)
    allocated.should be_a_kind_of String
    allocated.should eq '10.1.1.5/24'
    allocated2.should eq "#{ip.to_s}/#{ip.get_cid}"
  end

  it "should allocate a free ctid" do
    taken = Array(0..9) << '10'
    @openvz.allocate_ctid(taken).should eq 11
  end

  it "should convert " do
    @openvz.mb_to_pages(128).should eq 32768
  end

  it "should fail to run on windows" do
    @openvz.verify_dependencies.should raise_error(UserError, "You need to install OpenVZ first")
  end
end



