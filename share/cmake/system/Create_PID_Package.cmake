#########################################################################################
#	This file is part of the program PID						#
#  	Program description : build system supportting the PID methodology  		#
#  	Copyright (C) Robin Passama, LIRMM (Laboratoire d'Informatique de Robotique 	#
#	et de Microelectronique de Montpellier). All Right reserved.			#
#											#
#	This software is free software: you can redistribute it and/or modify		#
#	it under the terms of the CeCILL-C license as published by			#
#	the CEA CNRS INRIA, either version 1						#
#	of the License, or (at your option) any later version.				#
#	This software is distributed in the hope that it will be useful,		#
#	but WITHOUT ANY WARRANTY; without even the implied warranty of			#
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the			#
#	CeCILL-C License for more details.						#
#											#
#	You can be find the complete license description on the official website 	#
#	of the CeCILL licenses family (http://www.cecill.info/index.en.html)		#
#########################################################################################

list(APPEND CMAKE_MODULE_PATH ${WORKSPACE_DIR}/share/cmake/system)
list(APPEND CMAKE_MODULE_PATH ${WORKSPACE_DIR}/share/cmake/references)
list(APPEND CMAKE_MODULE_PATH ${WORKSPACE_DIR}/share/cmake/licenses)

include(Workspace_Internal_Functions NO_POLICY_SCOPE)

if(REQUIRED_PACKAGE)
	include(${WORKSPACE_DIR}/share/cmake/references/Refer${REQUIRED_PACKAGE}.cmake OPTIONAL RESULT_VARIABLE REQUIRED_STATUS)
	if(NOT REQUIRED_STATUS STREQUAL NOTFOUND)
		message("ERROR : A package with the same name ${REQUIRED_PACKAGE} is already referenced in the workspace")
		return()
	endif()
	if(EXISTS ${WORKSPACE_DIR}/packages/${REQUIRED_PACKAGE} AND IS_DIRECTORY ${WORKSPACE_DIR}/packages/${REQUIRED_PACKAGE})
		message("ERROR : A package with the same name ${REQUIRED_PACKAGE} is already present in the workspace")
		return()
	endif()
	if(OPTIONAL_LICENSE)
		include(${WORKSPACE_DIR}/share/cmake/licenses/License${OPTIONAL_LICENSE}.cmake OPTIONAL RESULT_VARIABLE REQUIRED_STATUS)
		if(REQUIRED_STATUS STREQUAL NOTFOUND)
			message("ERROR : License ${REQUIRED_LICENSE} does not refer to any known license in the workspace")
			return()
		endif()
	endif()
	create_PID_Package(	${REQUIRED_PACKAGE} 
				"${OPTIONAL_AUTHOR}" 
				"${OPTIONAL_INSTITUTION}"
				"${OPTIONAL_LICENSE}")
	if(OPTIONNAL_GIT_URL)
		get_Repository_Name(RES_NAME ${OPTIONNAL_GIT_URL})
		if(NOT "${RES_NAME}" STREQUAL "${REQUIRED_PACKAGE}")
			message("ERROR : the git url of the repository (${REQUIRED_GIT_URL}) does not define a repository with same name than package ${REQUIRED_PACKAGE}")
			return()
		endif()
		connect_PID_Package(	${REQUIRED_PACKAGE} 
					${OPTIONNAL_GIT_URL})
	endif()

	

else()
	message("ERROR : You must specify a name for the package to create using name=<name of package> argument")
endif()



