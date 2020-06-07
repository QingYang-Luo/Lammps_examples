# ********************  Lammps script  ********************

# ********************  This manual script started at 2020/5/10 17:00:31  ********************

# ********************  50*8*4 NaCl Crystal Thermal Conductivity  ******************** 

echo            both

# ********************  Initialization  *******************

units           metal
dimension       3
boundary        p       p       p
atom_style      charge
atom_modify     map     hash

# ********************  Read Data  *******************

read_restart	nvt.restart

# ********************  Potential  *******************

pair_style      born/coul/long	15.0

pair_coeff      1       1	0.263703306	0.316997401	2.34	1.048572898	0.499320477
pair_coeff	1	2	0.210962645	0.316997401	2.755	6.990485644	8.675806132
pair_coeff	2	2	0.161911664	0.316997401	3.17	72.40145986	145.4270695

kspace_style	pppm/stagger	5.0e-5

# ********************  Pre Variable  *******************

variable	T	equal	1000
variable        P       equal	1
variable        Dt      equal	0.001		#timestep

# ********************  Print Parameter  *******************

#thermo          1000
#thermo_style    custom  step    temp    lx      ly      lz      press   vol     pe      ke      etotal

# ********************  Minimize  *******************
#fix             1  all  nve 

#dump            1  all  custom  1000  dump.minstrc      id      type    x       y       z  
#dump_modify     1  sort id

#min_style       cg   
#minimize        1.0e-5  1.0e-8  1000000 1000000

#unfix           1
#undump          1

# ********************  Velocity Initialization  *******************
                                                             
#velocity	all  create  ${T}  853275  mom  yes  rot  yes  dist  gaussian

# ********************  Temperature per Atom/Group  ********************

reset_timestep	 0
timestep        ${Dt}

compute         ALLKe      all     ke/atom
variable        KB         equal   8.625e-5
variable        TEMP       atom    c_ALLKe/1.5/${KB}
fix             TolTpA     all     ave/atom      10   50000   500000   v_TEMP

# ********************  NPT Equilibrium Processing  ********************

#fix             NPT	all	npt     temp     ${T}      ${T}    0.1	iso	${P}      ${P}    0.5

#dump            1       all     custom  500000  dump.npt        id      type    x   y   z   f_TolTpA 
#dump_modify     1       sort    id                                                                 

#thermo_style    custom  step    temp   lx   ly   lz	press  	vol	pe  ke  etotal
#thermo          1000

#restart         250000   NPT*.restart

#run             500000

#undump          1
#unfix           NPT

#write_restart   npt.restart                 #binary file

#write_data      npt.data    nocoeff         #text file

# ********************  NVT Equilibrium Processing  ********************

#fix             NVT     all	nvt     temp     ${T}      ${T}    0.1

#dump            2       all     custom  500000  dump.nvt        id      type    x   y   z   f_TolTpA 
#dump_modify     2       sort    id                                                                 

#run	500000

#undump          2
#unfix           NVT

#write_restart   nvt.restart                 #binary file

#write_data      nvt.data    nocoeff         #text file

# ********************  Coordinate Variable  *******************

variable	xmax	equal	lx
variable	A_40	equal	${xmax}/40
variable	sor	equal	2*${A_40}
variable	mid	equal	${xmax}/2
variable	sikL	equal	${mid}-${sor}
variable	sikR	equal	${mid}+${sor}

# ********************  region and group  *******************

region		fix1	block	INF	-0.5	INF	INF	INF	INF	units box

region		fix2	block	278.5	INF	INF	INF	INF	INF	units box

region		sink	block	139	150.5	INF	INF	INF	INF	units box

region		source1	block	-0.5	5	INF	INF	INF	INF	units box
region		source2	block	272.9	278.5	INF	INF	INF	INF	units box

region		main	block	-0.5	278.5	INF	INF	INF	INF	units box
region		wall	union	2	fix1	fix2

group	hot1	region	source1
group	cold	region	sink
group	hot2	region	source2
group	freeze	region	wall
group	main_main	region	main

# ********************  Additional Thermal Parameter  ********************

compute	Thot1	hot1	temp/region     source1
compute	Tcold	cold	temp/region     sink

# ********************  2nd equilibrium processing  ********************

fix	nve	all	nve

compute         BLKX_40	all	chunk/atom	bin/1d	x	lower	${A_40}	units	box

fix	T_line_40	all	ave/chunk	200	2500	500000	BLKX_40	v_TEMP	file	temp_40.txt

fix	swap	all	thermal/conductivity	400	x	40

variable	tdiff	equal	c_Thot1-c_Tcold

dump            5       all     custom   500000   all*.une  id   type   x   y   z   f_TolTpA
dump_modify     5       sort    id

thermo_style    custom  step    temp	pe	ke	etotal	c_Thot1	c_Tcold	f_swap	v_tdiff
thermo          4000

restart         500000  2e*.restart

run             8000000

# ********************  thermal conductivity calculation processing  ********************

fix	swap	all	thermal/conductivity	400	x	40

thermo_style	custom	step	temp	pe	ke	etotal	f_swap	v_tdiff

restart		500000	RNEMD*.restart

run             4000000

write_restart   RNEMDfinal.restart

write_data      RNEMDfinal.data  nocoeff