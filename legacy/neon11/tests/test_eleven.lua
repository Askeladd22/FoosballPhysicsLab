package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local Tactics=require("src.tactics")
for _,role in ipairs({"RM","GK"}) do
 local s=Sim.new(role)
 assert(#s.players==22 and s.field.w==105 and s.field.h==68)
 assert(s.field.goalHalf==3.66)
 for team=1,2 do
  local seen,count,keeper={},0,0
  for _,p in ipairs(s.players) do
   if p.team==team then
    assert(not seen[p.number]);seen[p.number]=true
    count=count+1;if p.role=="GK" then keeper=keeper+1 end
    assert(p.x>=0 and p.x<=s.field.w and p.y>=0 and p.y<=s.field.h)
   end
  end
  assert(count==11 and keeper==1)
  local targets=Tactics.teamTargets(s,team)
  for p,target in pairs(targets) do
   assert(target.x>=4 and target.x<=s.field.w-4 and target.y>=7 and target.y<=s.field.h-7)
   assert(p~=s.controlled,"AI assigned human movement")
  end
 end
 for i,p in ipairs(s.players) do for j=i+1,#s.players do
  local q=s.players[j]
  assert((p.x-q.x)^2+(p.y-q.y)^2>(p.r+q.r)^2,"kickoff overlap")
 end end
 local id=s.controlled
 for _=1,100 do Sim.step(s,1/120) end
 assert(s.totalKicks==1 and s.phase=="play" and s.controlled==id)
end
print("PASS: 22 unique players, 4-4-2 anchors, field proportions, kickoff, fixed roles")
