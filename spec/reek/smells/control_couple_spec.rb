require File.join(File.dirname(File.dirname(File.dirname(File.expand_path(__FILE__)))), 'spec_helper')
require File.join(File.dirname(File.dirname(File.dirname(File.dirname(File.expand_path(__FILE__))))), 'lib', 'reek', 'smells', 'control_couple')
require File.join(File.dirname(File.expand_path(__FILE__)), 'smell_detector_shared')

include Reek::Smells

describe ControlCouple do
  before(:each) do
    @source_name = 'lets get married'
    @detector = ControlCouple.new(@source_name)
  end

  it_should_behave_like 'SmellDetector'

  context 'conditional on a parameter' do
    it 'should report a ternary check on a parameter' do
      'def simple(arga) arga ? @ivar : 3 end'.should reek_only_of(:ControlCouple, /arga/)
    end
    it 'should not report a ternary check on an ivar' do
      'def simple(arga) @ivar ? arga : 3 end'.should_not reek
    end
    it 'should not report a ternary check on a lvar' do
      'def simple(arga) lvar = 27; lvar ? arga : @ivar end'.should_not reek
    end
    it 'should spot a couple inside a block' do
      'def blocks(arg) @text.map { |blk| arg ? blk : "#{blk}" } end'.should reek_of(:ControlCouple, /arg/)
    end
  end

  context 'looking at the YAML' do
    before :each do
      src = <<EOS
def things(arg)
  @text.map do |blk|
    arg ? blk : "blk"
  end
  puts "hello" if arg
end
EOS
      ctx = MethodContext.new(nil, src.to_reek_source.syntax_tree)
      @detector.examine(ctx)
      smells = @detector.smells_found.to_a
      smells.length.should == 1
      @warning = smells[0]
    end

    it_should_behave_like 'common fields set correctly'

    it 'reports the control parameter' do
      @warning.smell[ControlCouple::PARAMETER_KEY].should == 'arg'
    end
    it 'reports all conditional locations' do
      @warning.lines.should == [3,6]
    end
  end
end
