module Diamond

  # The arpeggiator core
  class Arpeggiator

    include API::MIDI
    include API::Sequence
    include API::SequenceParameters

    attr_reader :parameter, :sequence, :sequencer

    # @param [Hash] options
    # @option options [Fixnum] :gate Duration of the arpeggiated notes. The value is a percentage based on the rate.  If the rate is 4, then a gate of 100 is equal to a quarter note. (default: 75) must be 1..500
    # @option options [Fixnum] :interval Increment (pattern) over (interval) scale degrees (range) times.  May be positive or negative. (default: 12)
    # @option options [Array<UniMIDI::Input, UniMIDI::Output>, UniMIDI::Input, UniMIDI::Output] :midi MIDI devices to use
    # @option options [Array<Hash>] :midi_control A user-defined mapping of MIDI cc to arpeggiator params
    # @option options [Boolean] :midi_debug Whether to send debug output about MIDI to standard out
    # @option options [Fixnum] :rx_channel (or :channel) Only respond to input messages to the given MIDI channel. will operate on all input sources. if not included, or nil the arpeggiator will work in omni mode and respond to all messages
    # @option options [Fixnum] :tx_channel Send output messages to the given MIDI channel despite what channel the input notes were intended for.
    # @option options [Fixnum] :pattern_offset Begin on the nth note of the sequence (but not omit any notes). (default: 0)
    # @option options [String, Pattern] :pattern Computes the contour of the arpeggiated melody.  Can be the name of a pattern or a pattern object.
    # @option options [Fixnum] :range Increment the (pattern) over (interval) scale degrees (range) times. Must be positive (abs will be used). (default: 3)
    # @option options [Fixnum] :rate How fast the arpeggios will be played. Must be positive (abs will be used). (default: 8, eighth note.) must be 0..resolution
    # @option options [Fixnum] :resolution Numeric resolution for rhythm (default: 128)   
    # @option options [Hash] :osc_control A user-defined map of OSC addresses and properties to arpeggiator params
    # @option options [Fixnum] :osc_port The port to listen for OSC on
    # @option options [Boolean] :osc_debug Whether to send debug output about OSC to standard out
    def initialize(options = {}, &block)
      resolution = options.fetch(:resolution, 128)

      @sequence = Sequence.new
      @parameter = SequenceParameters.new(@sequence, resolution, options) { @sequence.mark_changed }
      @sequencer = Sequencer.new

      initialize_midi(options)
      initialize_osc(options)
    end

    private

    # Initialize MIDI IO
    # @param [Hash] options
    # @option options [Array<UniMIDI::Input, UniMIDI::Output>, UniMIDI::Input, UniMIDI::Output] :midi MIDI devices to use
    # @option options [Array<Hash>] :midi_control A user-defined mapping of MIDI cc to arpeggiator params
    # @option options [Boolean] :midi_debug Whether to send debug output about MIDI to standard out
    # @option options [Fixnum] :rx_channel (or :channel) Only respond to input messages to the given MIDI channel. will operate on all input sources. if not included, or nil the arpeggiator will work in omni mode and respond to all messages
    # @option options [Fixnum] :tx_channel Send output messages to the given MIDI channel despite what channel the input notes were intended for.
    # @return [MIDI::Node]
     def initialize_midi(options = {})
      receive_channel = options[:rx_channel] || options[:channel]
      transmit_channel = options[:tx_channel]
      devices = MIDIInstrument::Device.partition(options[:midi])
      @midi = MIDI.new(devices, :debug => !!options[:midi_debug], :receive_channel => receive_channel, :transmit_channel => transmit_channel)
      @midi.enable_output(self)
      @midi.enable_note_control(self)
      @midi.enable_parameter_control(self, options[:midi_control]) if !options[:midi_control].nil?
      @midi
    end

    # @param [Hash] options
    # @option options [Hash] :osc_control A map of OSC addresses and properties
    # @option options [Fixnum] :osc_port The port to listen for OSC on
    # @return [OSC::Node]
    def initialize_osc(options = {})
      @osc = OSC.new(:debug => !!options[:osc_debug], :server_port => options[:osc_port])
      @osc.enable_parameter_control(@parameter, options[:osc_control]) if !options[:osc_control].nil?
      @osc
    end

  end

end
