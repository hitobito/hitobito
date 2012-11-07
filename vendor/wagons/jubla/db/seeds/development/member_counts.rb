
Census.seed(:year, 
  {year: 2011,
   start_at: Date.new(2011,8,1),
   finish_at: Date.new(2011,10,31)}
)

unless MemberCount.exists?
  Group::Flock.find_each do |flock|
    MemberCounter.new(2011, flock).count!
  end
end