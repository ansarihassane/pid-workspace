
##################################################################################
####################### configuring build time dependencies ######################
##################################################################################

###
#function(configure_Package_Build_Variables package mode)
#message(DEBUG configure_Package_Build_Variables package=${package} mode=${mode})
if(${package}_PREPARE_BUILD)#this is a guard to limit unecessary recursion
	return()
endif()

if(${package}_DURING_PREPARE_BUILD)#this is a guard to avoid cyclic recursion
	message(FATAL_ERROR "Alert : you have define cyclic dependencies between packages : Package ${package} is directly or undirectly requiring itself !")
endif()

if(mode MATCHES Release)
	set(mode_suffix "")
else()
	set(mode_suffix "_DEBUG")
endif()

set(${package}_DURING_PREPARE_BUILD TRUE)

# 1) initializing all build variable that are directly provided by each component of the target package
foreach(a_component IN ITEMS ${${package}_COMPONENTS})
	init_Component_Build_Variables(${package} ${a_component} ${${package}_ROOT_DIR} ${mode})
endforeach()

# 2) setting build variables with informations coming from package dependancies
foreach(a_component IN ITEMS ${${package}_COMPONENTS}) 
	foreach(a_package IN ITEMS ${${package}_${a_component}_DEPENDENCIES${mode_suffix}})
		foreach(a_dep_component IN ITEMS ${${package}_${a_component}_DEPENDENCY_${a_package}_COMPONENTS${mode_suffix}}) 
			update_Component_Build_Variables_With_Dependency(${package} ${a_component} ${a_package} ${a_dep_component} ${mode})
		endforeach()
	endforeach()
endforeach()

#3) setting build variables with informations coming from INTERNAL package dependancies
# these have not been checked like the others since the package components discovering mecanism has already done the job 
foreach(a_component IN ITEMS ${${package}_COMPONENTS}) 
	foreach(a_dep_component IN ITEMS ${${package}_${a_component}_INTERNAL_DEPENDENCIES${mode_suffix}}) 
		update_Component_Build_Variables_With_Internal_Dependency(${package} ${a_component} ${a_dep_component} ${mode})
	endforeach()
endforeach()

set(${package}_PREPARE_BUILD TRUE)
set(${package}_DURING_PREPARE_BUILD FALSE)
# no need to check system/external dependencies as they are already  treaten as special cases (see variable <package>__<component>_LINKS and <package>__<component>_DEFS of components)
# quite like in pkg-config tool
endfunction(configure_Package_Build_Variables)


###
function (update_Config_Include_Dirs package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_INCLUDE_DIRS${mode_suffix})	
		set(${package}_${component}_INCLUDE_DIRS${mode_suffix} ${${package}_${component}_INCLUDE_DIRS${mode_suffix}} ${${dep_package}_${dep_component}_INCLUDE_DIRS${mode_suffix}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Include_Dirs)

###
function (update_Config_Definitions package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_DEFINITIONS${mode_suffix})
		set(${package}_${component}_DEFINITIONS${mode_suffix} ${${package}_${component}_DEFINITIONS${mode_suffix}} ${${dep_package}_${dep_component}_DEFINITIONS${mode_suffix}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Definitions)

###
function(update_Config_Libraries package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_LIBRARIES${mode_suffix})
		set(	${package}_${component}_LIBRARIES${mode_suffix} 
			${${package}_${component}_LIBRARIES${mode_suffix}} 
			${${dep_package}_${dep_component}_LIBRARIES${mode_suffix}} 
			CACHE INTERNAL "") #putting dependencies after component using them (to avoid linker problems)
	endif()
endfunction(update_Config_Libraries)

###
function(init_Component_Build_Variables package component path_to_version mode)
	if(mode MATCHES Debug)
		set(mode_suffix "_DEBUG")
	else()
		set(mode_suffix "")
	endif()
	set(${package}_${component}_INCLUDE_DIRS${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_DEFINITIONS${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_LIBRARIES${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_EXECUTABLE${mode_suffix} "" CACHE INTERNAL "")
	is_Executable_Component(COMP_IS_EXEC ${package} ${component})
	
	if(NOT COMP_IS_EXEC)
		#provided include dirs (cflags -I<path>)
		set(${package}_${component}_INCLUDE_DIRS${mode_suffix} "${path_to_version}/include/${${package}_${component}_HEADER_DIR_NAME}" CACHE INTERNAL "")
		#additionally provided include dirs (cflags -I<path>) (external/system exported include dirs)
		if(${package}_${component}_INC_DIRS${mode_suffix})
			resolve_External_Includes_Path(RES_INCLUDES ${package} "${${package}_${component}_INC_DIRS${mode_suffix}}" ${mode})
			#message("DEBUG RES_INCLUDES for ${package} ${component} = ${RES_INCLUDES}")			
			set(	${package}_${component}_INCLUDE_DIRS${mode_suffix} 
				${${package}_${component}_INCLUDE_DIRS${mode_suffix}} 
				"${RES_INCLUDES}"
				CACHE INTERNAL "")
		endif()

		#provided cflags (own CFLAGS and external/system exported CFLAGS)
		if(${package}_${component}_DEFS${mode_suffix}) 	
			set(${package}_${component}_DEFINITIONS${mode_suffix} ${${package}_${component}_DEFS${mode_suffix}} CACHE INTERNAL "")
		endif()

		#provided library (ldflags -l<path>)
		## WITHOUT TARGET : uncomment following block
		if(NOT ${package}_${component}_TYPE STREQUAL "HEADER")
			set(${package}_${component}_LIBRARIES${mode_suffix} "${path_to_version}/lib/${${package}_${component}_BINARY_NAME${mode_suffix}}" CACHE INTERNAL "")
		endif()

		#provided additionnal ld flags (exported external/system libraries and ldflags)		
		if(${package}_${component}_LINKS${mode_suffix})
			resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_LINKS${mode_suffix}}" ${mode})
			set(	${package}_${component}_LIBRARIES${mode_suffix}
				${${package}_${component}_LIBRARIES${mode_suffix}}	
				"${RES_LINKS}"
				CACHE INTERNAL "")
		endif()
		#message("FINAL init_Component_Build_Variables ${package}.${component}: \nINCLUDES = ${${package}_${component}_INCLUDE_DIRS${mode_suffix}} (var=${package}_${component}_INCLUDE_DIRS${mode_suffix}) \nDEFINITIONS = ${${package}_${component}_DEFINITIONS${mode_suffix}} (var = ${package}_${component}_DEFINITIONS${mode_suffix}) \nLIBRARIES = ${${package}_${component}_LIBRARIES${mode_suffix}}\n")
	elseif(${package}_${component}_TYPE STREQUAL "APP" OR ${package}_${component}_TYPE STREQUAL "EXAMPLE")
		
		set(${package}_${component}_EXECUTABLE${mode_suffix} "${path_to_version}/bin/${${package}_${component}_BINARY_NAME${mode_suffix}}" CACHE INTERNAL "")
	endif()
endfunction(init_Component_Build_Variables)

### 
function(update_Component_Build_Variables_With_Dependency package component dep_package dep_component mode)
if(mode MATCHES Debug)
	set(mode_suffix "_DEBUG")
else()
	set(mode_suffix "")
endif()
configure_Package_Build_Variables(${dep_package} ${mode})#!! recursion to get all updated infos
if(${package}_${component}_EXPORT_${dep_package}_${dep_component}${mode_suffix})
	update_Config_Include_Dirs(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	update_Config_Definitions(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")	
else()
	if(NOT ${dep_package}_${dep_component}_TYPE STREQUAL "SHARED")#static OR header lib
		update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Dependency)


function(update_Component_Build_Variables_With_Internal_Dependency package component dep_component mode)
if(mode MATCHES Debug)
	set(mode_suffix "_DEBUG")
else()
	set(mode_suffix "")
endif()

if(${package}_${component}_INTERNAL_EXPORT_${dep_component}${mode_suffix})
	update_Config_Include_Dirs(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	update_Config_Definitions(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	update_Config_Libraries(${package} ${component} ${package} ${dep_component} "${mode_suffix}")	
else()#dep_component is not exported by component
	if(NOT ${package}_${dep_component}_TYPE STREQUAL "SHARED" AND NOT ${package}_${dep_component}_TYPE STREQUAL "MODULE")#static OR header lib
		update_Config_Libraries(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Internal_Dependency)
