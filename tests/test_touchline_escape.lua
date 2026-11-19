package.path="./?.lua;./?/init.lua;"..package.path
local Sim=require("src.sim")
local AI=require("src.ai")
for _,team in ipairs({1,2}) do
    for _,edge in ipairs({-1,1}) do
        local s=Sim.new("GK")
        s.phase="play"; s.setPiece=nil; s.lastTouch=team
        for i,p in ipairs(s.players) do p.x=10+i*9; p.y=35 end
        local p=s.players[team==1 and 4 or 9]
        s.ball.x=90
        s.ball.y=edge==1 and s.field.h-s.ball.r or s.ball.r
        p.x=s.ball.x-(team==1 and 1 or -1)*1.4
        p.y=s.ball.y-edge*2.1
        local x,y=s.ball.x,s.ball.y
        AI.update(s)
        assert(s.lastAction=="escape","IA did not choose a physical rail escape")
        assert(s.ball.x==x and s.ball.y==y,"escape teleported the ball")
        assert(s.totalKicks==1,"escape did not use a normal kick")
        for _=1,120 do Sim.step(s,1/120,{x=0,y=0}) end
        assert(s.ball.y>5 and s.ball.y<s.field.h-5,"ball remained trapped at rail")
        assert(s.restartCount==0,"escape generated a throw-in")
        assert(s.controlled.role=="GK","human control changed")
    end
end
print("PASS: physical touchline escape for both teams and both rails")
for _,side in ipairs({-1,1}) do
    for _,edge in ipairs({-1,1}) do
        local s=Sim.new("GK")
        s.phase="play"; s.setPiece=nil
        for i,p in ipairs(s.players) do p.x=10+i*9; p.y=35 end
        local p=s.players[side==1 and 9 or 4]
        s.lastTouch=p.team
        s.ball.x=side==1 and s.field.w+0.1 or -0.1
        s.ball.y=edge==1 and s.field.h-1.5 or 1.5
        p.x=s.ball.x-side*2.6
        p.y=s.ball.y
        AI.update(s)
        assert(s.lastAction=="escape","corner escape was not selected")
        for _=1,60 do
            Sim.step(s,1/120,{x=0,y=0})
            if s.phase=="restart" then break end
        end
        assert(s.phase=="restart" and s.restartCount==1,"corner ball did not cross endline")
        assert(s.score[1]==0 and s.score[2]==0,"corner escape scored an invalid goal")
        assert(s.setPiece.team==3-p.team,"wrong restart team")
    end
end
print("PASS: four corner escapes use physical kicks and normal endline restarts")
