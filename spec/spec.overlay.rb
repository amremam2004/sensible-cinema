require File.dirname(__FILE__) + '/common'
require_relative '../lib/overlayer'
# tell it not to actually mute during testing...
$TEST = true


def start_good_blank
  assert @o.blank?
end

def start_bad_blank
  assert @o.blank?
end


describe OverLayer do
  
  before do
    File.write 'temp.yml', YAML.dump({:mutes => {2.0 => 4.0}} )
    @o = OverLayer.new('temp.yml')
  end
  
  after do
    Thread.join_all_others
    File.delete 'temp.yml'
  end
  
  def start_good
    pps 'doing start_good', Time.now_f if $VERBOSE
    assert !@o.muted?
    sleep 1
  end
  
  def start_bad
    pps 'doing start_bad', Time.now_f if $VERBOSE
    assert @o.muted? # note this uses @o!
    sleep 1
  end
  
  it 'should reject overlapping settings...I guess'
  
  it 'should be able to mute' do
    # you shouldn't hear a beep
    assert !@o.muted?
    @o.mute!
    assert @o.muted?
    @o.unmute!
    assert !@o.muted?
    @o.mute!
    assert @o.muted?
  end
  
  context 'given you know when to start' do
    
    it 'should mute based on time' do   
      @o.start_thread
      # make sure we enter the mute section
      sleep 2.25
      start_bad
      sleep 1
      start_good
    end
    
    it 'should handle multiple mutes in a row' do
      File.write 'temp.yml', YAML.dump({:mutes => {2.0 => 4.0, 5.0 => 7.0}})
      @o = OverLayer.new 'temp.yml'
      @o.start_thread
      sleep 2.5
      start_bad # 1s
      sleep 2 # => 5.5
      start_bad
    end
    
    it 'should be able to mute teeny sequences' do
      File.write 'temp.yml', YAML.dump({:mutes => {0.0001 => 0.0002, 1.0 => 1.0001}})
      o = OverLayer.new 'temp.yml'
      o.continue_until_past_all_mutes false
    end
  end
  
  context 'startup' do
    it 'should allow you to change the current time' do
      @o.start_thread
      sleep 0.1 # wow ruby is slow...
      assert @o.cur_time > 0
      @o.set_seconds 5
      sleep 0.1
      assert @o.cur_time > 5
    end
    
    it 'should be able to land directly in or out of one'
    
    it 'should be able to hit keys to affect input' do
      @o = OverLayer.new 'test_yaml.yml'
      @o.cur_time
      @o.keyboard_input 'm'
      assert @o.cur_time > 59 
      @o.keyboard_input 'M'
      assert @o.cur_time < 59
      60.times {
        @o.keyboard_input 's'
      }
      assert @o.cur_time > 59 
      60.times {
        @o.keyboard_input 'S'
      }
      assert @o.cur_time < 59 
      600.times { 
        @o.keyboard_input 't' 
      }
      assert @o.cur_time > 59 
      600.times { 
        @o.keyboard_input 'T' 
      }
      assert @o.cur_time < 59 
    
    end
    
    it 'should be able to "key" into and out of a muted section and it work appropriately...'

  end

  it 'should have help output' do
    @o.status.should include("MmSs")
  end  

  it 'should allow for real yaml files somehow and use it' do
    # 2 - 3 , 4-5 should be muted
    @o = OverLayer.new 'test_yaml.yml'
    @o.start_thread
    start_good # takes 1s
    sleep 1.25
    start_bad
    start_good
    start_bad
    start_good
  end
  
  def write_yaml yaml
    File.write 'temp.yml', yaml
  end
  
  it 'should allow for 1:00.0 minute style input' do
    write_yaml <<YAML
:mutes:
  "0:02.0" : "0:03.0"
YAML
    @o = OverLayer.new 'temp.yml'
    @o.start_thread
    start_good
    start_good
    sleep 0.25
    start_bad
    start_good
  end

  it "should reload the YAML file on the fly to allow for editing it" do
    # start it with one far later
    write_yaml <<YAML
:mutes:
  "0:11.0" : "0:12.0"
YAML
    @o = OverLayer.new 'temp.yml'
    @o.start_thread
    start_good
    write_yaml <<YAML
:mutes:
  "0:00.0" : "0:01.5"
YAML
    # go forward a tenth
    # should reload it...
    @o.keyboard_input 'T'
    sleep 0.1 # blug
    start_bad
    start_good
  end
  
  it "should translate yaml well" do
    yaml = <<-YAML
:mutes:
  "0:02.0" : "0:03.0"
:blank_outs:
  "0:02.0" : "0:03.0"  
     YAML
     out = OverLayer.translate_yaml yaml
     out[:mutes].to_a.first.should == [2.0, 3.0]
     out[:blank_outs].to_a.first.should == [2.0, 3.0]
     yaml = <<-YAML
:mutes:
  "1:02.11" : "1:03.0"
     YAML
     out = OverLayer.translate_yaml yaml
     out[:mutes].to_a.first.should == [62.11, 63.0]
  end

  it "should disallow negative length intervals"

  it "should allow for 1:01:00.0 (double colon) style input" do
    $VERBOSE = 1 
    write_yaml <<-YAML
:mutes:
  "1:00.11" : "1:03.0"
    YAML
    @o = OverLayer.new 'temp.yml'
    @o.start_thread
    start_good
    @o.set_seconds 61
    sleep 0.1 # ruby rox again!
    start_bad
    sleep 2
    start_good
  end
  
  it "should be able to tell the player to sync to the closest second when the screen changes" do
    @o.start_thread
    start = Time.now
    while((Time.now - start) < 3) do
      @o.timestamp_changed
      sleep 0.1
    end
    @o.cur_time.should be < 1
    sleep 1
    10.times { @o.timestamp_changed }
    @o.cur_time.should be >= 1
    sleep 0.6
    @o.timestamp_changed
    @o.cur_time.should be >= 2
  end
    
  it "should have pure ruby for muting" do
    assert defined?(Muter)
    assert Muter.respond_to? :mute!
  end
  
  it "should handle blanks, too" do

    context "with a list that also includes" do
      
      File.write 'temp.yml', YAML.dump({:blank_outs => {2.0 => 4.0}} )
      @o = OverLayer.new('temp.yml')
      
      @o.start_thread
      start_good_blank
      sleep 1
      start_good_blank
      sleep 1
      start_bad_blank
      sleep 2
      start_good_blank
    end
    
  end
  
  # low prio
  
  it "could calculate the average delta of real seconds to seen on the player, and start to accomodate somehow, to stay lock on target"

  it "should allow for a static 'surround each' buffer"

  it "should have all output that is colon delimited"

  it 'should be able to continue *past* the very end, then back into it, etc.'
  
  it 'should have a user friendlier yaml syntax'

  it 'should have a more descriptive yaml syntax'
  
end