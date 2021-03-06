require File.join(File.expand_path(File.dirname(__FILE__)), 'test_utils')

include TZInfo

class TCTransitionDataTimezoneInfo < Minitest::Test

  def test_initialize_transitions
    o1 = TimezoneOffset.new(-17900,    0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 3600, :TESTD)
    o3 = TimezoneOffset.new(-18000,    0, :TESTS)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000, 4,1,1,0,0).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2000,10,1,1,0,0).to_i)
    t3 = TimezoneTransition.new(o2, o3, Time.utc(2001, 3,1,1,0,0).to_i)

    transitions = [t1, t2, t3]

    dti = TransitionDataTimezoneInfo.new('Test/Zone', transitions)

    assert_equal('Test/Zone', dti.identifier)
    assert_same(transitions, dti.transitions)
    assert_equal(true, dti.transitions.frozen?)
    assert_nil(dti.constant_offset)
  end

  def test_initialize_constant_offset
    o = TimezoneOffset.new(-17900, 0, :TESTLMT)
    dti = TransitionDataTimezoneInfo.new('Test/Zone', o)

    assert_equal('Test/Zone', dti.identifier)
    assert_same(o, dti.constant_offset)
    assert_nil(dti.transitions)
  end

  def test_initialize_empty_transitions
    error = assert_raises(ArgumentError) { TransitionDataTimezoneInfo.new('Test/Zone', []) }
    assert_match(/\btransitions_or_constant_offset\b/, error.message)
  end

  def test_initialize_nil_transitions_or_constant_offset_nil
    error = assert_raises(ArgumentError) { TransitionDataTimezoneInfo.new('Test/Zone', nil) }
    assert_match(/\btransitions_or_constant_offset\b/, error.message)
  end

  def test_initialize_transitions_or_constant_offset_incorrect_type
    o = Object.new
    error = assert_raises(ArgumentError) { TransitionDataTimezoneInfo.new('Test/Zone', o) }
    assert_match(/\btransitions_or_constant_offset\b/, error.message)
  end

  def test_period_for
    o1 = TimezoneOffset.new(-17900, 0,    :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 3600, :TESTD)
    o3 = TimezoneOffset.new(-18000, 0,    :TESTS)
    o4 = TimezoneOffset.new(-21600, 3600, :TESTD)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000, 4,1,1,0,0).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2000,10,1,1,0,0).to_i)
    t3 = TimezoneTransition.new(o2, o3, Time.utc(2001, 3,1,1,0,0).to_i)
    t4 = TimezoneTransition.new(o4, o2, Time.utc(2001, 4,1,1,0,0).to_i)
    t5 = TimezoneTransition.new(o3, o4, Time.utc(2001,10,1,1,0,0).to_i)
    t6 = TimezoneTransition.new(o3, o3, Time.utc(2002,10,1,1,0,0).to_i)
    t7 = TimezoneTransition.new(o2, o3, Time.utc(2003, 2,1,1,0,0).to_i)
    t8 = TimezoneTransition.new(o3, o2, Time.utc(2003, 3,1,1,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1,t2,t3,t4,t5,t6,t7,t8])

    assert_equal(TimezonePeriod.new(nil, t1), dti.period_for(Timestamp.for(Time.utc(1960, 1,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(nil, t1), dti.period_for(Timestamp.for(Time.utc(1999,12,1,0, 0, 0))))
    assert_equal(TimezonePeriod.new(nil, t1), dti.period_for(Timestamp.for(Time.utc(2000, 4,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t1, t2),  dti.period_for(Timestamp.for(Time.utc(2000, 4,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t1, t2),  dti.period_for(Timestamp.for(Time.utc(2000,10,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t2, t3),  dti.period_for(Timestamp.for(Time.utc(2000,10,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t2, t3),  dti.period_for(Timestamp.for(Time.utc(2001, 3,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t3, t4),  dti.period_for(Timestamp.for(Time.utc(2001, 3,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t3, t4),  dti.period_for(Timestamp.for(Time.utc(2001, 4,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t4, t5),  dti.period_for(Timestamp.for(Time.utc(2001, 4,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t4, t5),  dti.period_for(Timestamp.for(Time.utc(2001,10,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t5, t6),  dti.period_for(Timestamp.for(Time.utc(2001,10,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t5, t6),  dti.period_for(Timestamp.for(Time.utc(2002, 2,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t5, t6),  dti.period_for(Timestamp.for(Time.utc(2002,10,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t6, t7),  dti.period_for(Timestamp.for(Time.utc(2002,10,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t6, t7),  dti.period_for(Timestamp.for(Time.utc(2003, 2,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t7, t8),  dti.period_for(Timestamp.for(Time.utc(2003, 2,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t7, t8),  dti.period_for(Timestamp.for(Time.utc(2003, 3,1,0,59,59))))
    assert_equal(TimezonePeriod.new(t8, nil), dti.period_for(Timestamp.for(Time.utc(2003, 3,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t8, nil), dti.period_for(Timestamp.for(Time.utc(2004, 1,1,1, 0, 0))))
    assert_equal(TimezonePeriod.new(t8, nil), dti.period_for(Timestamp.for(Time.utc(2050, 1,1,1, 0, 0))))
  end

  def test_period_for_timestamp_with_zero_utc_offset
    o1 = TimezoneOffset.new(-17900, 0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 0, :TEST)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000,7,1,0,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1])

    assert_equal(TimezonePeriod.new(t1, nil), dti.period_for(Timestamp.for(Time.new(2000,7,1,0,0,0,0))))
  end

  def test_period_for_timestamp_with_non_zero_utc_offset
    o1 = TimezoneOffset.new(-17900, 0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 0, :TEST)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000,7,1,0,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1])

    assert_equal(TimezonePeriod.new(t1, nil), dti.period_for(Timestamp.for(Time.new(2000,6,30,23, 0, 0,-3600))))
    assert_equal(TimezonePeriod.new(nil, t1), dti.period_for(Timestamp.for(Time.new(2000,7, 1, 0,59,59, 3600))))
  end

  def test_period_for_no_transitions
    o1 = TimezoneOffset.new(-17900, 0, :TESTLMT)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', o1)

    assert_equal(TimezonePeriod.new(nil, nil, o1), dti.period_for(Timestamp.for(Time.utc(2005,1,1,0,0,0))))
    assert_equal(TimezonePeriod.new(nil, nil, o1), dti.period_for(Timestamp.for(Time.utc(2005,1,1,0,0,0))))
    assert_equal(TimezonePeriod.new(nil, nil, o1), dti.period_for(Timestamp.for(Time.utc(2005,1,1,0,0,0))))
  end

  def test_period_for_timestamp_with_unspecified_offset
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    assert_raises(ArgumentError) { dti.period_for(Timestamp.for(Time.utc(2005,1,1,0,0,0), offset: :ignore)) }
  end

  def test_period_for_nil
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    assert_raises(ArgumentError) { dti.period_for(nil) }
  end

  def test_periods_for_local
    o1 = TimezoneOffset.new(-17900,    0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 3600, :TESTD)
    o3 = TimezoneOffset.new(-18000,    0, :TESTS)
    o4 = TimezoneOffset.new(-21600, 3600, :TESTD)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000, 4,2,1,0,0).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2000,10,2,1,0,0).to_i)
    t3 = TimezoneTransition.new(o2, o3, Time.utc(2001, 3,2,1,0,0).to_i)
    t4 = TimezoneTransition.new(o4, o2, Time.utc(2001, 4,2,1,0,0).to_i)
    t5 = TimezoneTransition.new(o3, o4, Time.utc(2001,10,2,1,0,0).to_i)
    t6 = TimezoneTransition.new(o3, o3, Time.utc(2002,10,2,1,0,0).to_i)
    t7 = TimezoneTransition.new(o2, o3, Time.utc(2003, 2,2,1,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1,t2,t3,t4,t5,t6,t7])

    assert_equal([TimezonePeriod.new(nil, t1)], dti.periods_for_local(Timestamp.for(Time.utc(1960, 1, 1, 1, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(nil, t1)], dti.periods_for_local(Timestamp.for(Time.utc(1999,12, 1, 0, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(nil, t1)], dti.periods_for_local(Timestamp.for(Time.utc(2000, 1, 1,10, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(nil, t1)], dti.periods_for_local(Timestamp.for(Time.utc(2000, 4, 1,20, 1,39), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2000, 4, 1,20, 1,40), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2000, 4, 1,20,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1,  t2)], dti.periods_for_local(Timestamp.for(Time.utc(2000, 4, 1,21, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1,  t2)], dti.periods_for_local(Timestamp.for(Time.utc(2000,10, 1,19,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1,  t2),
                  TimezonePeriod.new(t2,  t3)], dti.periods_for_local(Timestamp.for(Time.utc(2000,10, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1,  t2),
                  TimezonePeriod.new(t2,  t3)], dti.periods_for_local(Timestamp.for(Time.utc(2000,10, 1,20,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t2,  t3)], dti.periods_for_local(Timestamp.for(Time.utc(2000,10, 1,21, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t2,  t3)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 3, 1,19,59,59), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2001, 3, 1,20, 0, 0), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2001, 3, 1,20,30, 0), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2001, 3, 1,20,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t3,  t4)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 3, 1,21, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t3,  t4)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 4, 1,19,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t3,  t4),
                  TimezonePeriod.new(t4,  t5)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 4, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t3,  t4),
                  TimezonePeriod.new(t4,  t5)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 4, 1,20,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t4,  t5)], dti.periods_for_local(Timestamp.for(Time.utc(2001, 4, 1,21, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t4,  t5)], dti.periods_for_local(Timestamp.for(Time.utc(2001,10, 1,19,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t5,  t6)], dti.periods_for_local(Timestamp.for(Time.utc(2001,10, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t5,  t6)], dti.periods_for_local(Timestamp.for(Time.utc(2002, 2, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t5,  t6)], dti.periods_for_local(Timestamp.for(Time.utc(2002,10, 1,19,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t6,  t7)], dti.periods_for_local(Timestamp.for(Time.utc(2002,10, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t6,  t7)], dti.periods_for_local(Timestamp.for(Time.utc(2003, 2, 1,19,59,59), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2003, 2, 1,20, 0, 0), offset: :ignore)))
    assert_equal([],                            dti.periods_for_local(Timestamp.for(Time.utc(2003, 2, 1,20,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t7, nil)], dti.periods_for_local(Timestamp.for(Time.utc(2003, 2, 1,21, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t7, nil)], dti.periods_for_local(Timestamp.for(Time.utc(2004, 2, 1,20, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t7, nil)], dti.periods_for_local(Timestamp.for(Time.utc(2040, 2, 1,20, 0, 0), offset: :ignore)))
  end

  def test_periods_for_local_warsaw
    o1 = TimezoneOffset.new(5040,    0, :LMT)
    o2 = TimezoneOffset.new(5040,    0, :WMT)
    o3 = TimezoneOffset.new(3600,    0, :CET)
    o4 = TimezoneOffset.new(3600, 3600, :CEST)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(1879,12,31,22,36,0).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(1915, 8, 4,22,36,0).to_i)
    t3 = TimezoneTransition.new(o4, o3, Time.utc(1916, 4,30,22, 0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Europe/Warsaw', [t1,t2,t3])

    assert_equal([TimezonePeriod.new(t1, t2),
                  TimezonePeriod.new(t2, t3)], dti.periods_for_local(Timestamp.for(Time.utc(1915,8,4,23,40,0), offset: :ignore)))
  end

  def test_periods_for_local_single_transition
    o1 = TimezoneOffset.new(-3600, 0, :TESTD)
    o2 = TimezoneOffset.new(-3600, 0, :TESTS)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2000,7,1,0,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1])

    assert_equal([TimezonePeriod.new(nil, t1)], dti.periods_for_local(Timestamp.for(Time.utc(2000,6,30,22,59,59), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1, nil)], dti.periods_for_local(Timestamp.for(Time.utc(2000,6,30,23, 0, 0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(t1, nil)], dti.periods_for_local(Timestamp.for(Time.utc(2000,7, 1, 0, 0, 0), offset: :ignore)))
  end

  def test_periods_for_local_no_transitions
    o1 = TimezoneOffset.new(-17900, 0, :TESTLMT)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', o1)

    assert_equal([TimezonePeriod.new(nil, nil, o1)], dti.periods_for_local(Timestamp.for(Time.utc(2005,1,1,0,0,0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(nil, nil, o1)], dti.periods_for_local(Timestamp.for(Time.utc(2005,1,1,0,0,0), offset: :ignore)))
    assert_equal([TimezonePeriod.new(nil, nil, o1)], dti.periods_for_local(Timestamp.for(Time.utc(2005,1,1,0,0,0), offset: :ignore)))
  end

  def test_periods_for_local_timestamp_with_specified_offset
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    t = Timestamp.for(Time.utc(2005,1,1,0,0,0))

    assert_raises(ArgumentError) { dti.periods_for_local(t) }
  end

  def test_periods_for_local_nil
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    assert_raises(ArgumentError) { dti.periods_for_local(nil) }
  end

  def test_transitions_up_to
    o1 = TimezoneOffset.new(-17900,    0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000, 3600, :TESTD)
    o3 = TimezoneOffset.new(-18000,    0, :TESTS)
    o4 = TimezoneOffset.new(-21600, 3600, :TESTD)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2010, 4,1,1,0,0).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2010,10,1,1,0,0).to_i)
    t3 = TimezoneTransition.new(o2, o3, Time.utc(2011, 3,1,1,0,0).to_i)
    t4 = TimezoneTransition.new(o4, o2, Time.utc(2011, 4,1,1,0,0).to_i)
    t5 = TimezoneTransition.new(o3, o4, Time.utc(2011,10,1,1,0,0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1,t2,t3,t4,t5])

    assert_equal([],               dti.transitions_up_to(Timestamp.for(Time.utc(2010, 4,1,1,0,0))))
    assert_equal([],               dti.transitions_up_to(Timestamp.for(Time.utc(2010, 4,1,1,0,0)), Timestamp.for(Time.utc(2000, 1,1,0,0,0))))
    assert_equal([t1],             dti.transitions_up_to(Timestamp.for(Time.utc(2010, 4,1,1,0,1))))
    assert_equal([t1],             dti.transitions_up_to(Timestamp.for(Time.utc(2010, 4,1,1,0,1)), Timestamp.for(Time.utc(2000, 1,1,0,0,0))))
    assert_equal([t2,t3,t4],       dti.transitions_up_to(Timestamp.for(Time.utc(2011, 4,1,1,0,1)), Timestamp.for(Time.utc(2010,10,1,1,0,0))))
    assert_equal([t2,t3,t4],       dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,0)), Timestamp.for(Time.utc(2010, 4,1,1,0,1))))
    assert_equal([t3],             dti.transitions_up_to(Timestamp.for(Time.utc(2011, 4,1,1,0,0)), Timestamp.for(Time.utc(2010,10,1,1,0,1))))
    assert_equal([],               dti.transitions_up_to(Timestamp.for(Time.utc(2011, 3,1,1,0,0)), Timestamp.for(Time.utc(2010,10,1,1,0,1))))
    assert_equal([t1,t2,t3,t4],    dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,0))))
    assert_equal([t1,t2,t3,t4,t5], dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,1))))
    assert_equal([t1,t2,t3,t4,t5], dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,0,1))))
    assert_equal([t1,t2,t3,t4,t5], dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,1)), Timestamp.for(Time.utc(2010, 4,1,1,0,0))))
    assert_equal([t2,t3,t4,t5],    dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,1)), Timestamp.for(Time.utc(2010, 4,1,1,0,1))))
    assert_equal([t2,t3,t4,t5],    dti.transitions_up_to(Timestamp.for(Time.utc(2011,10,1,1,0,1)), Timestamp.for(Time.utc(2010, 4,1,1,0,0,1))))
    assert_equal([t5],             dti.transitions_up_to(Timestamp.for(Time.utc(2015, 1,1,0,0,0)), Timestamp.for(Time.utc(2011,10,1,1,0,0))))
    assert_equal([],               dti.transitions_up_to(Timestamp.for(Time.utc(2015, 1,1,0,0,0)), Timestamp.for(Time.utc(2011,10,1,1,0,1))))
  end

  def test_transitions_up_to_timestamp_with_zero_utc_offset
    o1 = TimezoneOffset.new(-17900,    0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000,    0, :TESTS)
    o3 = TimezoneOffset.new(-18000, 3600, :TESTD)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2009,12,31,23,59,59).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2010, 7, 1, 0, 0, 0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1,t2])

    assert_equal([t1,t2], dti.transitions_up_to(Timestamp.for(Time.new(2010,7,1,0,0,1,0))))
    assert_equal([t1,t2], dti.transitions_up_to(Timestamp.for(Time.new(2011,1,1,0,0,0,0)), Timestamp.for(Time.new(2009,12,31,23,59,59,0))))
  end

  def test_transitions_up_to_timestamp_with_non_zero_utc_offset
    o1 = TimezoneOffset.new(-17900,    0, :TESTLMT)
    o2 = TimezoneOffset.new(-18000,    0, :TESTS)
    o3 = TimezoneOffset.new(-18000, 3600, :TESTD)

    t1 = TimezoneTransition.new(o2, o1, Time.utc(2009,12,31,23,59,59).to_i)
    t2 = TimezoneTransition.new(o3, o2, Time.utc(2010, 7, 1, 0, 0, 0).to_i)

    dti = TransitionDataTimezoneInfo.new('Test/Zone', [t1,t2])

    assert_equal([t1,t2], dti.transitions_up_to(Timestamp.for(Time.new(2010,6,30,23,0,1,-3600))))
    assert_equal([t1],    dti.transitions_up_to(Timestamp.for(Time.new(2010,7, 1, 1,0,0, 3600))))
    assert_equal([t1,t2], dti.transitions_up_to(Timestamp.for(Time.new(2011,1,1,0,0,0,0)), Timestamp.for(Time.new(2010, 1, 1, 0,59,59, 3600))))
    assert_equal([t2],    dti.transitions_up_to(Timestamp.for(Time.new(2011,1,1,0,0,0,0)), Timestamp.for(Time.new(2009,12,31,23, 0, 0,-3600))))
  end

  def test_transitions_up_to_no_transitions
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    assert_equal([], dti.transitions_up_to(Timestamp.for(Time.utc(2015,1,1,0,0,0))))
  end

  def test_transitions_up_to_to_not_greater_than_from
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    to = Timestamp.for(Time.utc(2012,8,1,0,0,0))
    from = Timestamp.for(Time.utc(2013,8,1,0,0,0))

    assert_raises(ArgumentError) { dti.transitions_up_to(to, from) }
  end

  def test_transitions_up_to_to_not_greater_than_from_subsecond
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    to = Timestamp.for(Time.utc(2012,8,1,0,0,0))
    from = Timestamp.for(Time.utc(2012,8,1,0,0,0,1))

    assert_raises(ArgumentError) { dti.transitions_up_to(to, from) }
  end

  def test_transitions_up_to_to_timestamp_with_unspecified_offset
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    to = Timestamp.for(Time.utc(2015,1,1,0,0,0), offset: :ignore)

    assert_raises(ArgumentError) { dti.transitions_up_to(to) }
  end

  def test_transitions_up_to_from_timestamp_with_unspecified_offset
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    to = Timestamp.for(Time.utc(2015,1,1,0,0,0))
    from = Timestamp.for(Time.utc(2014,1,1,0,0,0), offset: :ignore)

    assert_raises(ArgumentError) { dti.transitions_up_to(to, from) }
  end

  def test_transitions_up_to_to_timestamp_nil
    dti = TransitionDataTimezoneInfo.new('Test/Zone', TimezoneOffset.new(-17900, 0, :TESTLMT))

    assert_raises(ArgumentError) { dti.transitions_up_to(nil) }
  end
end
