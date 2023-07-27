local BackendUtils = {}

function BackendUtils.repairedCFrameSnailVersion(cf)
	local sq=math.sqrt
	local x,y,z,a,b,c,d,e,f,g,h,i=cf:components()
	local j,k,l=f*g-d*i,a*i-c*g,c*d-a*f
	local m,n,o=d*l-k*g,j*g-l*a,a*k-j*d
	local l1,l2,l3=sq(a^2+d^2+g^2),sq(j^2+k^2+l^2),sq(m^2+n^2+o^2)
	return CFrame.new(x,y,z,a/l1,j/l2,m/l3,d/l1,k/l2,n/l3,g/l1,l/l2,o/l3)
end

function BackendUtils.repairedCFrame(cf)
	local x,y,z,a,b,c,d,e,f,g,h,i=cf:components()
	local j,k,l=f*g-d*i,a*i-c*g,c*d-a*f
	local m,n,o=d*l-k*g,j*g-l*a,a*k-j*d
	local l1,l2,l3=(a^2+d^2+g^2)^0.5,(j^2+k^2+l^2)^0.5,(m^2+n^2+o^2)^0.5
	return CFrame.new(x,y,z,a/l1,j/l2,m/l3,d/l1,k/l2,n/l3,g/l1,l/l2,o/l3)
end

return BackendUtils