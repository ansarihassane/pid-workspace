
#######################################################################################################
############# variables generated by generic functions using the Use<package>-<version>.cmake #########
############# files of each dependent package - contain full path information #########################
#######################################################################################################
# for libraries components
# XXX_YYY_INCLUDE_DIRS[_DEBUG]	# all include path to use to build an executable with the library component YYY of package XXX
# XXX_YYY_DEFINITIONS[_DEBUG]	# all definitions to use to build an executable with the library component YYY of package XXX
# XXX_YYY_LIBRARIES[_DEBUG]	# all libraries path to use to build an executable with the library component YYY of package XXX

########### this part is for runtime purpose --- see later ##############
# for application components
# XXX_YYY_EXECUTABLE[_DEBUG]	# path to the executable component YYY of package XXX

# for "launch" components (not currently existing)
# XXX_YYY_APPS[_DEBUG]		# all executables of a distributed application defined by launch component YYY of package XXX
# XXX_YYY_APP_ZZZ_PARAMS[_DEBUG]# all parameters used  
# XXX_YYY_APP_ZZZ_PARAM_VVV	# string parameter VVV for application ZZZ used by the launch file YYY of package XXX 

#TODO managing the automatic installation of binay packages or git repo (if not exist) !!

##################################################################################
####################### configuring build time dependencies ######################
##################################################################################
###
function(test_Package_Location DEPENDENCIES_NOTFOUND package dependency)
	if(NOT ${${dependency}_FOUND})

		if(${${package}_DEPENDENCY_${dependency}_VERSION} STREQUAL "")
			message(SEND_ERROR "The required package ${a_dependency} has not been found !")
		elseif(${${package}_DEPENDENCY_${dependency}_VERSION_EXACT})
			message(SEND_ERROR "The required package ${a_dependency} with exact version ${${package}_DEPENDENCY_${dependency}_VERSION} has not been found !")
		else()
			message(SEND_ERROR "The required package ${a_dependency} with version compatible with ${${package}_DEPENDENCY_${dependency}_VERSION} has not been found !")
		endif()
		set(${DEPENDENCIES_NOTFOUND} ${DEPENDENCIES_NOTFOUND} ${dependency} PARENT_SCOPE)
	endif()
endfunction()


###
# each dependent package version is defined as ${package}_DEPENDENCY_${dependency}_VERSION
# other variables set by the package version use file 
# ${package}_DEPENDENCY_${dependency}_REQUIRED		# TRUE if package is required FALSE otherwise (QUIET MODE)
# ${package}_DEPENDENCY_${dependency}_VERSION		# version if a version if specified
# ${package}_DEPENDENCY_${dependency}_VERSION_EXACT	# TRUE if exact version is required
# ${package}_DEPENDENCY_${dependency}_COMPONENTS	# list of components
function(resolve_Package_Dependency package dependency)

if(${dependency}_FOUND) #the dependency has already been found (previously found in iteration or recursion, not possible to import it again)
	if(${package}_DEPENDENCY_${dependency}_VERSION) # a specific version is required
	 	if( ${package}_DEPENDENCY_${dependency}_VERSION_EXACT) #an exact version is required
			
			is_Exact_Version_Compatible_With_Previous_Constraints(IS_COMPATIBLE NEED_REFIND ${dependency} ${${package}_DEPENDENCY_${dependency}_VERSION}) # will be incompatible if a different exact version already required OR if another major version required OR if another minor version greater than the one of exact version
 
			if(IS_COMPATIBLE)
				if(NEED_REFIND)
					# OK installing the exact version instead
					#WARNING call to find package
					find_package(
						${dependency} 
						${${package}_DEPENDENCY_${dependency}_VERSION} 
						EXACT
						MODULE
						REQUIRED
						${${package}_DEPENDENCY_${dependency}_COMPONENTS}
					)
				endif()
				return()				
			else() #not compatible
				message(FATAL_ERROR "impossible to find compatible versions regarding versions constraints for package ${package}")
				return()
			endif()
		else()#not an exact version required
			is_Version_Compatible_With_Previous_Constraints (
					COMPATIBLE_VERSION VERSION_TO_FIND 
					${dependency} ${${package}_DEPENDENCY_${dependency}_VERSION})
			if(COMPATIBLE_VERSION)
				if(VERSION_TO_FIND)
					find_package(
						${dependency} 
						${VERSION_TO_FIND}
						MODULE
						REQUIRED
						${${package}_DEPENDENCY_${dependency}_COMPONENTS}
					)
				else()
					return() # nothing to do more, the current used version is compatible with everything 	
				endif()
			else()
				message(FATAL_ERROR "impossible to find compatible versions regarding versions constraints for package ${package}")
				return()
			endif()
		endif()
	else()
		return()#by default the version is compatible (no constraints) so return 
	endif()
else()#the dependency has not been already found
	if(	${package}_DEPENDENCY_${dependency}_VERSION)
		
		if(${package}_DEPENDENCY_${dependency}_VERSION_EXACT) #an exact version has been specified
			#WARNING recursive call to find package
			find_package(
				${dependency} 
				${${package}_DEPENDENCY_${dependency}_VERSION} 
				EXACT
				MODULE
				REQUIRED
				${${package}_DEPENDENCY_${dependency}_COMPONENTS}
			)

		else()
			#WARNING recursive call to find package
			find_package(
				${dependency} 
				${${package}_DEPENDENCY_${dependency}_VERSION} 
				MODULE
				REQUIRED
				${${package}_DEPENDENCY_${dependency}_COMPONENTS}
			)
		endif()
	else()
		find_package(
			${dependency} 
			MODULE
			REQUIRED
			${${package}_DEPENDENCY_${dependency}_COMPONENTS}
		)
	endif()
endif()
test_Package_Location(DEPENDENCIES_NOTFOUND ${package} ${dependency})
set(${package}_DEPENDENCIES_NOTFOUND ${DEPENDENCIES_NOTFOUND} PARENT_SCOPE)
endfunction(resolve_Package_Dependency)

###
function (update_Config_Include_Dirs package component dep_package dep_component)
	if(${dep_package}_${dep_component}_INCLUDE_DIRS${USE_MODE_SUFFIX})	
		set(${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX} ${${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX}} ${${dep_package}_${dep_component}_INCLUDE_DIRS${USE_MODE_SUFFIX}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Include_Dirs)

###
function (update_Config_Definitions package component dep_package dep_component)
	if(${dep_package}_${dep_component}_DEFINITIONS${USE_MODE_SUFFIX})
		set(${package}_${component}_DEFINITIONS${USE_MODE_SUFFIX} ${${package}_${component}_DEFINITIONS${USE_MODE_SUFFIX}} ${${dep_package}_${dep_component}_DEFINITIONS${USE_MODE_SUFFIX}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Definitions)

###
function(update_Config_Libraries package component dep_package dep_component)
	if(${dep_package}_${dep_component}_LIBRARIES${USE_MODE_SUFFIX})
		set(	${package}_${component}_LIBRARIES${USE_MODE_SUFFIX} 
			${${package}_${component}_LIBRARIES${USE_MODE_SUFFIX}} 
			${${dep_package}_${dep_component}_LIBRARIES${USE_MODE_SUFFIX}} 
			CACHE INTERNAL "") #putting dependencies before using component dependencies (to avoid linker problems)
	endif()
endfunction(update_Config_Libraries)

###
function(init_Component_Build_Variables package component path_to_version)
	set(${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX} "" CACHE INTERNAL "")
	set(${package}_${component}_DEFINITIONS${USE_MODE_SUFFIX} "" CACHE INTERNAL "")
	set(${package}_${component}_LIBRARIES${USE_MODE_SUFFIX} "" CACHE INTERNAL "")
	set(${package}_${component}_EXECUTABLE${USE_MODE_SUFFIX} "" CACHE INTERNAL "")
	is_Executable_Component(COMP_IS_EXEC ${package} ${component})
	
	if(NOT COMP_IS_EXEC)
		#provided include dirs (cflags -I<path>)
		set(${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX} "${path_to_version}/include/${${package}_${component}_HEADER_DIR_NAME}" CACHE INTERNAL "")
		
		#additional provided include dirs (cflags -I<path>) (external/system exported include dirs)
		if(${package}_${component}_INC_DIRS${USE_MODE_SUFFIX})
			set(	${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX} 
				${${package}_${component}_INCLUDE_DIRS${USE_MODE_SUFFIX}} 
				${${package}_${component}_INC_DIRS${USE_MODE_SUFFIX}} 
				CACHE INTERNAL "")
		endif()
		#provided cflags (own CFLAGS and external/system exported CFLAGS)
		if(${package}_${component}_DEFS${USE_MODE_SUFFIX}) 	
			set(${package}_${component}_DEFINITIONS${USE_MODE_SUFFIX} ${${package}_${component}_DEFS${USE_MODE_SUFFIX}} CACHE INTERNAL "")
		endif()

		#provided library (ldflags -l<path>)
		if(NOT ${package}_${component}_TYPE STREQUAL "HEADER")
			set(${package}_${component}_LIBRARIES${USE_MODE_SUFFIX} "${path_to_version}/lib/${${package}_${component}_BINARY_NAME${USE_MODE_SUFFIX}}" CACHE INTERNAL "")
		endif()

		#provided additionnal ld flags (exported external/system libraries and ldflags)
		if(${package}_${component}_LINKS${USE_MODE_SUFFIX})
			set(	${package}_${component}_LIBRARIES${USE_MODE_SUFFIX}
				${${package}_${component}_LIBRARIES${USE_MODE_SUFFIX}}				
				${${package}_${component}_LINKS${USE_MODE_SUFFIX}}
				CACHE INTERNAL "")
		endif()
		
	elseif(${package}_${component}_TYPE STREQUAL "APP" OR ${package}_${component}_TYPE STREQUAL "EXAMPLE")
		
		set(${package}_${component}_EXECUTABLE${USE_MODE_SUFFIX} "${path_to_version}/bin/${${package}_${component}_BINARY_NAME${USE_MODE_SUFFIX}}" CACHE INTERNAL "")
	endif()
endfunction(init_Component_Build_Variables)

### 
function(update_Component_Build_Variables_With_Dependency package component dep_package dep_component)
configure_Package_Build_Variables(${dep_package})#!! recursion to get all updated infos
if(${package}_${component}_EXPORT_${dep_package}_${dep_component}${USE_MODE_SUFFIX})
	update_Config_Include_Dirs(${package} ${component} ${dep_package} ${dep_component})
	update_Config_Definitions(${package} ${component} ${dep_package} ${dep_component})
	update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component})	
else()
	if(NOT ${dep_package}_${dep_component}_TYPE STREQUAL "SHARED")#static OR header lib
		update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component})
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Dependency package)


function(update_Component_Build_Variables_With_Internal_Dependency package component dep_component)
if(${package}_${component}_INTERNAL_EXPORT_${dep_component}${USE_MODE_SUFFIX})
	update_Config_Include_Dirs(${package} ${component} ${package} ${dep_component})
	update_Config_Definitions(${package} ${component} ${package} ${dep_component})
	update_Config_Libraries(${package} ${component} ${package} ${dep_component})	
else()#dep_component is not exported by component
	if(NOT ${package}_${dep_component}_TYPE STREQUAL "SHARED")#static OR header lib
		update_Config_Libraries(${package} ${component} ${package} ${dep_component})
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Internal_Dependency)


function(resolve_Package_Dependencies package build_mode_suffix)
# 1) managing package dependencies (the list of dependent packages is defined as ${package_name}_DEPENDENCIES)
# - locating dependent packages in the workspace and configuring their build variables recursively 
foreach(dep_pack IN ITEMS ${${package}_DEPENDENCIES${build_mode_suffix}})
	# 1) resolving direct dependencies
	resolve_Package_Dependency(${package} ${dep_pack})
	if(${dep_pack}_FOUND)
		if(${package}_DEPENDENCIES${build_mode_suffix})
			resolve_Package_Dependencies(${dep_pack} "${build_mode_suffix}")#recursion : resolving dependencies for each package dependency
		endif()
	else() #package dependency not resolved 
		list(APPEND ${package}_NOT_FOUND_DEPS ${dep_pack})		
	endif()
endforeach()

# 2) for not found package
if(${package}_NOT_FOUND_DEPS)
	message("there are not found dependencies !!")
	foreach(not_found_dep_pack IN ITEMS ${${package}_NOT_FOUND_DEPS})
		if(REQUIRED_PACKAGES_AUTOMATIC_DOWNLOAD)
			message(FATAL_ERROR "there are some unresolved required package dependencies : ${${PROJECT_NAME}_TOINSTALL_PACKAGES}. Automatic download of package not supported yet")#TODO
			return()
		else()	
			message(FATAL_ERROR "there are some unresolved required package dependencies : ${${PROJECT_NAME}_TOINSTALL_PACKAGES}. You may download them \"by hand\" or use the required packages automatic download option")
			return()
		endif()
	endforeach()
endif()
endfunction(resolve_Package_Dependencies)

###
function(configure_Package_Build_Variables package_name)
if(${package_name}_PREPARE_BUILD)#this is a guard to limit recursion
	return()
endif()

if(${package_name}_DURING_PREPARE_BUILD)
	message(FATAL_ERROR "Alert : you have define cyclic dependencies between packages : Package ${package_name} is directly or undirectly requiring itself !")
endif()

set(${package_name}_DURING_PREPARE_BUILD TRUE)

# 1) initializing all build variable that are directly provided by each component of the target package
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS})
	init_Component_Build_Variables(${package_name} ${a_component}$ ${${package_name}_ROOT_DIR})
endforeach()

# 2) setting build variables with informations coming from package dependancies
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS}) 
	foreach(a_package IN ITEMS ${${package_name}_${a_component}_DEPENDENCIES${USE_MODE_SUFFIX}})
		#message("undirect dependencies for ${package_name} ${a_component}") 
		foreach(a_dep_component IN ITEMS ${${package_name}_${a_component}_DEPENDENCY_${a_package}_COMPONENTS${USE_MODE_SUFFIX}}) 
			update_Component_Build_Variables_With_Dependency(${package_name} ${a_component} ${a_package} ${a_dep_component})
		endforeach()
	endforeach()
endforeach()

#3) setting build variables with informations coming from INTERNAL package dependancies
# these have not been checked like the others since the package components discovering mecanism has already done the job 
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS}) 
	foreach(a_dep_component IN ITEMS ${${package_name}_${a_component}_INTERNAL_DEPENDENCIES${USE_MODE_SUFFIX}}) 
		update_Component_Build_Variables_With_Internal_Dependency(${package_name} ${a_component} ${a_dep_component})
	endforeach()
endforeach()

set(${package_name}_PREPARE_BUILD TRUE)
set(${package_name}_DURING_PREPARE_BUILD FALSE)
# no need to check system/external dependencies as they are already  treaten as special cases (see variable <package>__<component>_LINKS and <package>__<component>_DEFS of components)
# quite like in pkg-config tool
endfunction(configure_Package_Build_Variables)


##################################################################################
################## finding shared libs dependencies for the linker ###############
##################################################################################

function(resolve_Source_Component_Linktime_Dependencies component THIRD_PARTY_LINKS)
is_Executable_Component(COMP_IS_EXEC ${PROJECT_NAME} ${component})
will_be_Built(COMP_WILL_BE_BUILT ${component})

if(	NOT COMP_IS_EXEC 
	OR NOT COMP_WILL_BE_BUILT)#special case for executables that need rpath link to be specified (due to system shared libraries linking system)-> the linker must resolve all target links (even shared libs) transitively
	return()
endif()

set(undirect_deps)
# 0) no need to search for system libraries as they are installed and found automatically by the OS binding mechanism, idem  for external dependencies since they are always direct dependencies for the currenlty build component

# 1) searching each direct dependency in other packages
foreach(dep_package IN ITEMS ${${PROJECT_NAME}_${component}_DEPENDENCIES${USE_MODE_SUFFIX}})
	foreach(dep_component IN ITEMS ${${PROJECT_NAME}_${component}_DEPENDENCY_${dep_package}_COMPONENTS${USE_MODE_SUFFIX}})
		set(LIST_OF_DEP_SHARED)
		find_Dependent_Private_Shared_Libraries(LIST_OF_DEP_SHARED ${dep_package} ${dep_component} TRUE)
		if(LIST_OF_DEP_SHARED)
			list(APPEND undirect_deps ${LIST_OF_DEP_SHARED})
		endif()
	endforeach()
endforeach()

# 2) searching each direct dependency in current package (no problem with undirect internal dependencies since undirect path only target install path which is not a problem for build)
foreach(dep_component IN ITEMS ${${PROJECT_NAME}_${component}_INTERNAL_DEPENDENCIES${USE_MODE_SUFFIX}})
	set(LIST_OF_DEP_SHARED)
	find_Dependent_Private_Shared_Libraries(LIST_OF_DEP_SHARED ${PROJECT_NAME} ${dep_component} TRUE)
	if(LIST_OF_DEP_SHARED)
		list(APPEND undirect_deps ${LIST_OF_DEP_SHARED})
	endif()
endforeach()


if(undirect_deps) #if true we need to be sure that the rpath-link does not contain some dirs of the rpath (otherwise the executable may not run)
	list(REMOVE_DUPLICATES undirect_deps)	
	get_target_property(thelibs ${component}${INSTALL_NAME_SUFFIX} LINK_LIBRARIES)
	set_target_properties(${component}${INSTALL_NAME_SUFFIX} PROPERTIES LINK_LIBRARIES "${thelibs};${undirect_deps}")
	set(${THIRD_PARTY_LINKS} ${undirect_deps} PARENT_SCOPE)
endif()
endfunction(resolve_Source_Component_Linktime_Dependencies)


function(find_Dependent_Private_Shared_Libraries LIST_OF_UNDIRECT_DEPS package component is_direct)
set(undirect_list)
# 0) no need to search for systems dependencies as they can be found automatically using OS shared libraries binding mechanism

# 1) searching external dependencies TODO
#foreach(dep_package IN ITEMS ${${package}_${component}_EXTERNAL_DEPENDENCIES${USE_MODE_SUFFIX}})
#	if(${package}_EXTERNAL_DEPENDENCY_${dep_package}_USE_RUNTIME${USE_MODE_SUFFIX}) #the package has shared libs
#		#HERE TODO revoir les dépendences externes (j'ai besoin de savoir pour chaque lib externe à quel package externe elle fait référence)
#	endif()
#endforeach()

# 2) searching in dependent packages
foreach(dep_package IN ITEMS ${${package}_${component}_DEPENDENCIES${USE_MODE_SUFFIX}})
	foreach(dep_component IN ITEMS ${${package}_${component}_DEPENDENCY_${dep_package}_COMPONENTS${USE_MODE_SUFFIX}}) 
		set(UNDIRECT)
		if(is_direct) # current component is a direct dependency of the application
			if(	${dep_package}_${dep_component}_TYPE STREQUAL "STATIC"
				OR ${dep_package}_${dep_component}_TYPE STREQUAL "HEADER"
				OR ${package}_${component}_EXPORTS_${dep_package}_${dep_component}${USE_MODE_SUFFIX})
				 #the potential shared lib dependencies of the header or static lib will be direct dependencies of the application OR the shared lib dependency is a direct dependency of the application 
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} TRUE) 
			else()#it is a shared lib that is not exported
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE) #the shared lib dependency is NOT a direct dependency of the application 
				list(APPEND undirect_list "${${dep_package}_ROOT_DIR}/lib/${${dep_package}_${dep_component}_BINARY_NAME${USE_MODE_SUFFIX}}")				
			endif()
		else() #current component is NOT a direct dependency of the application
			if(	${dep_package}_${dep_component}_TYPE STREQUAL "STATIC"
				OR ${dep_package}_${dep_component}_TYPE STREQUAL "HEADER")
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE)
			else()#it is a shared lib that is exported or NOT
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE) #the shared lib dependency is a direct dependency of the application 
				list(APPEND undirect_list "${${dep_package}_ROOT_DIR}/lib/${${dep_package}_${dep_component}_BINARY_NAME${USE_MODE_SUFFIX}}")				
			endif()
		endif()		
		
		if(UNDIRECT)
			list(APPEND undirect_list ${UNDIRECT})
		endif()
	endforeach()
endforeach()

# 3) searching in current package
foreach(dep_component IN ITEMS ${${package}_${component}_INTERNAL_DEPENDENCIES${USE_MODE_SUFFIX}})
	set(UNDIRECT)
	if(is_direct) # current component is a direct dependency of the application
		if(	${package}_${dep_component}_TYPE STREQUAL "STATIC"
			OR ${package}_${dep_component}_TYPE STREQUAL "HEADER"
			OR ${package}_${component}_INTERNAL_EXPORTS_${dep_component}${USE_MODE_SUFFIX})
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} TRUE) #the potential shared lib dependencies of the header or static lib will be direct dependencies of the application OR the shared lib dependency is a direct dependency of the application 
		else()#it is a shared lib that is not exported
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE) #the shared lib dependency is NOT a direct dependency of the application 
			list(APPEND undirect_list "${${package}_ROOT_DIR}/lib/${${package}_${dep_component}_BINARY_NAME${USE_MODE_SUFFIX}}")				
		endif()
	else() #current component is NOT a direct dependency of the application
		if(	${package}_${dep_component}_TYPE STREQUAL "STATIC"
			OR ${package}_${dep_component}_TYPE STREQUAL "HEADER")
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE)
		else()#it is a shared lib that is exported or NOT
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE) #the shared lib dependency is NOT a direct dependency of the application in all cases 
			list(APPEND undirect_list "${${package}_ROOT_DIR}/lib/${${package}_${dep_component}_BINARY_NAME${USE_MODE_SUFFIX}}")				
		endif()
	endif()
	
	if(UNDIRECT)
		list(APPEND undirect_list ${UNDIRECT})
	endif()
endforeach()


if(undirect_list) #if true we need to be sure that the rpath-link does not contain some dirs of the rpath (otherwise the executable may not run)
	list(REMOVE_DUPLICATES undirect_list)
	set(${LIST_OF_UNDIRECT_DEPS} "${undirect_list}" PARENT_SCOPE)
endif()
endfunction(find_Dependent_Private_Shared_Libraries)


##################################################################################
################## binary packages configuration #################################
##################################################################################

### resolve runtime dependencies for packages
function(resolve_Package_Runtime_Dependencies package build_mode)
if(${package}_PREPARE_RUNTIME)#this is a guard to limit recursion -> the runtime has already been prepared
	return()
endif()

if(${package}_DURING_PREPARE_RUNTIME)
	message(FATAL_ERROR "Alert : cyclic dependencies between packages found : Package ${package_name} is undirectly requiring itself !")
	return()
endif()
set(${package}_DURING_PREPARE_RUNTIME TRUE)

if(build_mode MATCHES Debug)
set(MODE_SUFFIX _DEBUG)
elseif(build_mode MATCHES Release) 
set(MODE_SUFFIX "")
else()
message(FATAL_ERROR "bad argument, unknown mode \"${build_mode}\"")
endif()

if(${package}_DEPENDENCIES${MODE_SUFFIX}) #first resolving dependencies by recursion
	foreach(dep IN ITEMS ${${package}_DEPENDENCIES${MODE_SUFFIX}})
		resolve_Package_Runtime_Dependencies(${dep} ${build_mode})
	endforeach()
endif()
foreach(component IN ITEMS ${${package}_COMPONENTS${MODE_SUFFIX}})
	resolve_Bin_Component_Runtime_Dependencies(${package} ${component} ${build_mode})
endforeach()
set(${package}_DURING_PREPARE_RUNTIME FALSE)
set(${package}_PREPARE_RUNTIME TRUE)
endfunction(resolve_Package_Runtime_Dependencies)


### resolve runtime dependencies for components
function(resolve_Bin_Component_Runtime_Dependencies package component mode)
if(	${package}_${component}_TYPE STREQUAL "SHARED" 
	OR ${package}_${component}_TYPE STREQUAL "APP" 
	OR ${package}_${component}_TYPE STREQUAL "EXAMPLE")
	get_Bin_Component_Runtime_Dependencies(ALL_SHARED_LIBS ${package} ${component} ${mode})#suppose that findPackage has resolved everything
	create_Bin_Component_Symlinks(${package} ${component} ${mode} "${ALL_SHARED_LIBS}")
endif()
endfunction(resolve_Bin_Component_Runtime_Dependencies)


### configuring components runtime paths (links to libraries)
function(create_Bin_Component_Symlinks bin_package bin_component mode shared_libs)
if(mode MATCHES Release)
	set(mode_string "")
elseif(mode MATCHES Debug)
	set(mode_string "-dbg")
else()
	return()
endif()

foreach(lib IN ITEMS ${shared_libs})
	get_filename_component(A_LIB_FILE ${lib} NAME)
	execute_process(
		COMMAND ${CMAKE_COMMAND} -E remove -f ${${bin_package}_ROOT_DIR}/.rpath/${bin_component}${mode_string}/${A_LIB_FILE}
		COMMAND ${CMAKE_COMMAND} -E create_symlink ${lib} ${${bin_package}_ROOT_DIR}/.rpath/${bin_component}${mode_string}/${A_LIB_FILE}
	)
endforeach()
endfunction(create_Bin_Component_Symlinks)


### recursive function to find runtime dependencies
function(get_Bin_Component_Runtime_Dependencies ALL_SHARED_LIBS package component mode)
	if(mode MATCHES Release)
		set(mode_binary_suffix "")
		set(mode_var_suffix "")
	elseif(mode MATCHES Debug)
		set(mode_binary_suffix "-dbg")
		set(mode_var_suffix "_DEBUG")
	else()
		return()
	endif()
	set(result "")

	# 1) adding direct external dependencies
	if(${package}_${component}_LINKS${mode_var_suffix})
		foreach(lib IN ITEMS ${${package}_${component}_LINKS${mode_var_suffix}})
			get_filename_component(LIB_TYPE ${lib} EXT)
			if(LIB_TYPE)
				if(UNIX AND NOT APPLE) 		
					if(LIB_TYPE MATCHES "^.*\.so(\..+)*$")#found shared lib
						list(APPEND result ${lib})#adding external dependencies
					endif()
				elseif(APPLE)
					if(LIB_TYPE MATCHES "^.*\.dylib(\..+)*$")#found shared lib
						list(APPEND result ${lib})#adding external dependencies
					endif()
				elseif(WIN32)
					if(LIB_TYPE MATCHES "^.*\.dll(\..+)*$")#found shared lib
						list(APPEND result ${lib})#adding external dependencies
					endif()
				endif()
			endif()
		endforeach()
	endif()
	#message("DEBUG runtime deps for component ${component}, AFTER DIRECT EXTERNAL DEPENDENCIES => ${result} ")
	# 2) adding package components dependencies
	foreach(dep_pack IN ITEMS ${${package}_${component}_DEPENDENCIES${mode_var_suffix}})
		#message("DEBUG : ${component}  depends on package ${dep_pack}")
		foreach(dep_comp IN ITEMS ${${package}_${component}_DEPENDENCY_${dep_pack}_COMPONENTS${mode_var_suffix}})
			#message("DEBUG : ${component} depends on package ${dep_comp} in ${dep_pack}")
			if(${dep_pack}_${dep_comp}_TYPE STREQUAL "HEADER" OR ${dep_pack}_${dep_comp}_TYPE STREQUAL "STATIC")		
				get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${dep_pack} ${dep_comp} ${mode}) #need to resolve external symbols whether the component is exported or not (it may have unresolved symbols coming from shared libraries)
				if(INT_DEP_SHARED_LIBS)
					list(APPEND result ${INT_DEP_SHARED_LIBS})
				endif()
			elseif(${dep_pack}_${dep_comp}_TYPE STREQUAL "SHARED")
				list(APPEND result ${${dep_pack}_ROOT_DIR}/lib/${${dep_pack}_${dep_comp}_BINARY_NAME${mode_var_suffix}})#the shared library is a direct dependency of the component
				is_Bin_Component_Exporting_Other_Components(EXPORTING ${dep_pack} ${dep_comp} ${mode})
				if(EXPORTING) # doing transitive search only if shared libs export something
					get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${dep_pack} ${dep_comp} ${mode}) #need to resolve external symbols whether the component is exported or not
					if(INT_DEP_SHARED_LIBS)# guarding against shared libs presence
						list(APPEND result ${INT_DEP_SHARED_LIBS})
					endif()
				endif() #no need to resolve external symbols if the shared library component is not exported
			endif()
		endforeach()
	endforeach()
	#message("DEBUG : runtime deps for component ${component}, AFTER PACKAGE DEPENDENCIES => ${result} ")

	# 3) adding internal components dependencies (only case when recursion is needed)
	foreach(int_dep IN ITEMS ${${package}_${component}_INTERNAL_DEPENDENCIES${mode_var_suffix}})
		if(${package}_${int_dep}_TYPE STREQUAL "HEADER" OR ${package}_${int_dep}_TYPE STREQUAL "STATIC")		
			get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${package} ${int_dep} ${mode}) #need to resolve external symbols whether the component is exported or not (it may have unresolved symbols coming from shared libraries)
			if(INT_DEP_SHARED_LIBS)
				list(APPEND result ${INT_DEP_SHARED_LIBS})
			endif()
		elseif(${package}_${int_dep}_TYPE STREQUAL "SHARED")
			# no need to link internal dependencies with symbolic links (they will be found automatically)
			is_Bin_Component_Exporting_Other_Components(EXPORTING ${package} ${int_dep} ${mode})
			if(EXPORTING) # doing transitive search only if shared libs export something
				get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${package} ${int_dep} ${mode}) #need to resolve external symbols whether the component is exported or not
				if(INT_DEP_SHARED_LIBS)# guarding against shared libs presence
					list(APPEND result ${INT_DEP_SHARED_LIBS})
				endif()
			endif() #no need to resolve external symbols if the shared library component is not exported
		endif()
	endforeach()
	#message("DEBUG : runtime deps for component ${component}, AFTER INTERNAL DEPENDENCIES => ${result} ")
	# 4) adequately removing first duplicates in the list
	list(REVERSE result)
	list(REMOVE_DUPLICATES result)
	list(REVERSE result)
	#message("DEBUG : runtime deps for component ${component}, AFTER RETURNING => ${result} ")
	set(${ALL_SHARED_LIBS} ${result} PARENT_SCOPE)
endfunction(get_Bin_Component_Runtime_Dependencies)



#resolving dependencies
function(is_Bin_Component_Exporting_Other_Components RESULT package component mode)
set(${RESULT} FALSE PARENT_SCOPE)
if(mode MATCHES Release)
	set(mode_var_suffix "")
elseif(mode MATCHES Debug)
	set(mode_var_suffix "_DEBUG")
else()
	message(FATAL_ERROR "Bug : unknown mode ${mode}")
	return()
endif()
#scanning external dependencies
if(${package}_${component}_LINKS${mode_var_suffix}) #only exported links here
	set(${RESULT} TRUE PARENT_SCOPE)
	return()
endif()

# scanning internal dependencies
if(${package}_${component}_INTERNAL_DEPENDENCIES${mode_var_suffix})
	foreach(int_dep IN ITEMS ${package}_${component}_INTERNAL_DEPENDENCIES${mode_var_suffix})
		if(${package}_${component}_INTERNAL_EXPORT_${int_dep}${mode_var_suffix})
			set(${RESULT} TRUE PARENT_SCOPE)
			return()
		endif()
	endforeach()		
endif()

# scanning package dependencies
foreach(dep_pack IN ITEMS ${package}_${component}_DEPENDENCIES${mode_var_suffix})
	foreach(ext_dep IN ITEMS ${package}_${component}_DEPENDENCY_${dep_pack}_COMPONENTS${mode_var_suffix})
		if(${package}_${component}_EXPORT_${dep_pack}_${ext_dep}${mode_var_suffix})
			set(${RESULT} TRUE PARENT_SCOPE)
			return()
		endif()
	endforeach()
endforeach()
endfunction(is_Bin_Component_Exporting_Other_Components)

##################################################################################
####################### source package run time dependencies #####################
##################################################################################


### configuring source components (currntly built) runtime paths (links to libraries)
function(create_Source_Component_Symlinks bin_component shared_libs)
foreach(lib IN ITEMS ${shared_libs})
	get_filename_component(A_LIB_FILE "${lib}" NAME)	
	install(CODE "
		execute_process(COMMAND ${CMAKE_COMMAND} -E remove -f ${${PROJECT_NAME}_INSTALL_RPATH_DIR}/${bin_component}/${A_LIB_FILE} WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})
		execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${lib} ${${PROJECT_NAME}_INSTALL_RPATH_DIR}/${bin_component}/${A_LIB_FILE} WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX})
		")# creating links "on the fly" when installing
endforeach()
endfunction(create_Source_Component_Symlinks)

### 
function(resolve_Source_Component_Runtime_Dependencies component THIRD_PARTY_LIBS)
if(	${PROJECT_NAME}_${component}_TYPE STREQUAL "SHARED" 
	OR ${PROJECT_NAME}_${component}_TYPE STREQUAL "APP" 
	OR ${PROJECT_NAME}_${component}_TYPE STREQUAL "EXAMPLE" )
	get_Bin_Component_Runtime_Dependencies(ALL_SHARED_LIBS ${PROJECT_NAME} ${component} ${CMAKE_BUILD_TYPE})
	if(THIRD_PARTY_LIBS)
		list(APPEND ALL_SHARED_LIBS ${THIRD_PARTY_LIBS})
	endif()
	create_Source_Component_Symlinks(${component}${INSTALL_NAME_SUFFIX} "${ALL_SHARED_LIBS}")
endif()
endfunction(resolve_Source_Component_Runtime_Dependencies)


##################################################################################
############################## install the dependancies ########################## 
########### functions used to create the use<package><version>.cmake  ############ 
##################################################################################
function(write_Use_File file package_name build_mode)
set(MODE_SUFFIX "")
if(${build_mode} MATCHES Release) #mode independent info written only once in the release mode 
	file(APPEND ${file} "######### declaration of package components ########\n")
	file(APPEND ${file} "set(${package_name}_COMPONENTS ${${package_name}_COMPONENTS} CACHE INTERNAL \"\")\n")
	file(APPEND ${file} "set(${package_name}_COMPONENTS_APPS ${${package_name}_COMPONENTS_APPS} CACHE INTERNAL \"\")\n")
	file(APPEND ${file} "set(${package_name}_COMPONENTS_LIBS ${${package_name}_COMPONENTS_LIBS} CACHE INTERNAL \"\")\n")
	
	file(APPEND ${file} "####### internal specs of package components #######\n")
	foreach(a_component IN ITEMS ${${package_name}_COMPONENTS_LIBS})
		file(APPEND ${file} "set(${package_name}_${a_component}_TYPE ${${package_name}_${a_component}_TYPE} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_${a_component}_HEADER_DIR_NAME ${${package_name}_${a_component}_HEADER_DIR_NAME} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_${a_component}_HEADERS ${${package_name}_${a_component}_HEADERS} CACHE INTERNAL \"\")\n")
	endforeach()
	foreach(a_component IN ITEMS ${${package_name}_COMPONENTS_APPS})
		file(APPEND ${file} "set(${package_name}_${a_component}_TYPE ${${package_name}_${a_component}_TYPE} CACHE INTERNAL \"\")\n")
	endforeach()
else()
	set(MODE_SUFFIX _DEBUG)
endif()

#mode dependent info written adequately depending the mode 

# 1) external package dependencies
file(APPEND ${file} "#### declaration of external package dependencies in ${CMAKE_BUILD_TYPE} mode ####\n")
file(APPEND ${file} "set(${package_name}_EXTERNAL_DEPENDENCIES${MODE_SUFFIX} ${${package_name}_EXTERNAL_DEPENDENCIES${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")

foreach(a_ext_dep IN ITEMS ${${package_name}_EXTERNAL_DEPENDENCIES${MODE_SUFFIX}})
	file(APPEND ${file} "set(${package_name}_EXTERNAL_DEPENDENCY_${a_ext_dep}_REFERENCE_PATH${MODE_SUFFIX} ${${package_name}_EXTERNAL_DEPENDENCY_${a_ext_dep}_REFERENCE_PATH${MODE_SUFFIX}} CACHE PATH \"path to the root dir of ${a_ext_dep} external package\")\n")
	file(APPEND ${file} "set(${package_name}_EXTERNAL_DEPENDENCY_${a_ext_dep}_USE_RUNTIME${MODE_SUFFIX} ${${package_name}_EXTERNAL_DEPENDENCY_${a_ext_dep}_USE_RUNTIME${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")	
endforeach()

# 2) package dependencies
file(APPEND ${file} "#### declaration of package dependencies in ${CMAKE_BUILD_TYPE} mode ####\n")
file(APPEND ${file} "set(${package_name}_DEPENDENCIES${MODE_SUFFIX} ${${package_name}_DEPENDENCIES${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
foreach(a_dep IN ITEMS ${${package_name}_DEPENDENCIES${MODE_SUFFIX}})
		file(APPEND ${file} "set(${package_name}_DEPENDENCY_${a_dep}_VERSION${MODE_SUFFIX} ${${package_name}_DEPENDENCY_${a_dep}_VERSION${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_DEPENDENCY_${a_dep}_VERSION_EXACT${MODE_SUFFIX} ${${package_name}_DEPENDENCY_${a_dep}_VERSION_EXACT${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_DEPENDENCY_${a_dep}_COMPONENTS${MODE_SUFFIX} ${${package_name}_DEPENDENCY_${a_dep}_COMPONENTS${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
endforeach()

# 3) internal components specifications
file(APPEND ${file} "#### declaration of components exported flags and binary in ${CMAKE_BUILD_TYPE} mode ####\n")
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS})
	is_Built_Component(IS_BUILT_COMP ${package_name} ${a_component})
	is_Executable_Component(IS_EXEC_COMP ${package_name} ${a_component})
	if(IS_BUILT_COMP)#if not a pure header library
		file(APPEND ${file} "set(${package_name}_${a_component}_BINARY_NAME${MODE_SUFFIX} ${${package_name}_${a_component}_BINARY_NAME${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
	endif()
	if(NOT IS_EXEC_COMP)#it is a library
		file(APPEND ${file} "set(${package_name}_${a_component}_INC_DIRS${MODE_SUFFIX} ${${package_name}_${a_component}_INC_DIRS${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_${a_component}_DEFS${MODE_SUFFIX} ${${package_name}_${a_component}_DEFS${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		file(APPEND ${file} "set(${package_name}_${a_component}_LINKS${MODE_SUFFIX} ${${package_name}_${a_component}_LINKS${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
	endif()
endforeach()

# 4) package internal component dependencies
file(APPEND ${file} "#### declaration package internal component dependencies in ${CMAKE_BUILD_TYPE} mode ####\n")
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS})
	if(${package_name}_${a_component}_INTERNAL_DEPENDENCIES${MODE_SUFFIX}) # the component has internal dependencies
		file(APPEND ${file} "set(${package_name}_${a_component}_INTERNAL_DEPENDENCIES${MODE_SUFFIX} ${${package_name}_${a_component}_INTERNAL_DEPENDENCIES${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		foreach(a_int_dep IN ITEMS ${${package_name}_${a_component}_INTERNAL_DEPENDENCIES${MODE_SUFFIX}})
			if(${package_name}_${a_component}_INTERNAL_EXPORT_${a_int_dep}${MODE_SUFFIX})
				file(APPEND ${file} "set(${package_name}_${a_component}_INTERNAL_EXPORT_${a_int_dep}${MODE_SUFFIX} TRUE CACHE INTERNAL \"\")\n")				
			else()
				file(APPEND ${file} "set(${package_name}_${a_component}_INTERNAL_EXPORT_${a_int_dep}${MODE_SUFFIX} FALSE CACHE INTERNAL \"\")\n")			
			endif()
		endforeach()
	endif()
endforeach()

# 5) component dependencies 
file(APPEND ${file} "#### declaration of component dependencies in ${CMAKE_BUILD_TYPE} mode ####\n")
foreach(a_component IN ITEMS ${${package_name}_COMPONENTS})
	if(${package_name}_${a_component}_DEPENDENCIES${MODE_SUFFIX}) # the component has package dependencies
		file(APPEND ${file} "set(${package_name}_${a_component}_DEPENDENCIES${MODE_SUFFIX} ${${package_name}_${a_component}_DEPENDENCIES${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
		foreach(dep_package IN ITEMS ${${package_name}_${a_component}_DEPENDENCIES${MODE_SUFFIX}})
			file(APPEND ${file} "set(${package_name}_${a_component}_DEPENDENCY_${dep_package}_COMPONENTS${MODE_SUFFIX} ${${package_name}_${a_component}_DEPENDENCY_${dep_package}_COMPONENTS${MODE_SUFFIX}} CACHE INTERNAL \"\")\n")
			foreach(dep_component IN ITEMS ${${package_name}_${a_component}_DEPENDENCY_${dep_package}_COMPONENTS${MODE_SUFFIX}})
				if(${package_name}_${a_component}_EXPORT_${dep_package}_${dep_component})
					file(APPEND ${file} "set(${package_name}_${a_component}_EXPORT_${dep_package}_${dep_component}${MODE_SUFFIX} TRUE CACHE INTERNAL \"\")\n")
				else()
					file(APPEND ${file} "set(${package_name}_${a_component}_EXPORT_${dep_package}_${dep_component}${MODE_SUFFIX} FALSE CACHE INTERNAL \"\")\n")
				endif()
			endforeach()
		endforeach()
	endif()
endforeach()
endfunction(write_Use_File)

function(create_Use_File)
if(${CMAKE_BUILD_TYPE} MATCHES Release) #mode independent info written only once in the release mode 
	set(file ${CMAKE_BINARY_DIR}/share/Use${PROJECT_NAME}-${${PROJECT_NAME}_VERSION}.cmake)
else()
	set(file ${CMAKE_BINARY_DIR}/share/UseDebugTemp)
endif()

#resetting the file content
file(WRITE ${file} "")
write_Use_File(${file} ${PROJECT_NAME} ${CMAKE_BUILD_TYPE})

#finalizing release mode by agregating info from the debug mode
if(${CMAKE_BUILD_TYPE} MATCHES Release) #mode independent info written only once in the release mode 
	file(READ "${CMAKE_BINARY_DIR}/../debug/share/UseDebugTemp" DEBUG_CONTENT)
	file(APPEND ${file} "${DEBUG_CONTENT}")
endif()
endfunction(create_Use_File)
