export

	#advection_diffusion.jl
	FEM_heatflow,
	implicitEulerStepFamily,
	ADimplicitEulerStep,

	#ellipticLCS.jl
	Singularity,
	getcoords,
	getindices,
	EllipticBarrier,
	EllipticVortex,
	LCSParameters,
	s1dist,
	p1dist,
	compute_singularities,
	singularity_detection,
	critical_point_detection,
	combine_singularities,
	compute_returning_orbit,
	compute_closed_orbits,
	ellipticLCS,
	constrainedLCS,
	materialbarriers,
    combine_20,
    combine_31,
    combine_20_aggressive,

	#diffusion_operators.jl
	gaussian,
	gaussiancutoff,
	KNN,
	MutualKNN,
	Neighborhood,
	DM_heatflow,
	sparse_diff_op_family,
	sparse_diff_op,
	kde_normalize!,
	row_normalize!,
	sparse_adjacency_family,
	sparse_adjacency,
	stationary_distribution,
	diffusion_coordinates,
	diffusion_distance,

	#dynamicmetrics
	STmetric,
	stmetric,
	spdist,

	#FEMassembly.jl
	assembleStiffnessMatrix,
	assembleMassMatrix,

	#gridfunctions.jl
	regular1dGridTypes,
	regular2dGridTypes,
	regular1dGrid,
	regular1dP2Grid,
	regularTriangularGrid,
	regularDelaunayGrid,
	irregularDelaunayGrid,
	randomDelaunayGrid,
	regularP2TriangularGrid,
	regularP2DelaunayGrid,
	regularQuadrilateralGrid,
	regularP2QuadrilateralGrid,
	regularTetrahedralGrid,
	regularP2TetrahedralGrid,
	regularGrid,
	randomDelaunayGrid,
	evaluate_function_from_dofvals,
	evaluate_function_from_node_or_cellvals,
	evaluate_function_from_node_or_cellvals_multiple,
	locatePoint,
	nodal_interpolation,
    sample_to,
	undoBCS,
	doBCS,
	applyBCS,
	getHomDBCS,
	boundaryData,
	nBCDofs,
	getDofCoordinates,
	getCellMidpoint,

	#numericalExperiments.jl
	makeOceanFlowTestCase,
	makeDoubleGyreTestCase,
	experimentResult,
	runExperiment!,
	plotExperiment,

	#ulam,jl
	ulam,

	#plotting.jl
	plot_u,
	plot_u!,
	plot_spectrum,
	plot_real_spectrum,
	plot_u_eulerian,
	plot_ftle,
	eulerian_videos,
	eulerian_video,
	plot_barrier,
	plot_barrier!,
	plot_singularities,
	plot_singularities!,
	plot_vortices,
	plot_vortices!,

	#pullbacktensors.jl
	flow,
	linearized_flow,
	mean_diff_tensor,
	CG_tensor,
	pullback_tensors,
	pullback_metric_tensor,
	pullback_diffusion_tensor,
	pullback_diffusion_tensor_function,
	pullback_SDE_diffusion_tensor,
	av_weighted_CG_tensor,

	#streammacros.jl
    @define_stream,
    @velo_from_stream,
    @var_velo_from_stream,
	@vorticity_from_stream,

	#TO.jl
	nonAdaptiveTOCollocation,
	adaptiveTOCollocation,
	adaptiveTOCollocationStiffnessMatrix,
	L2GalerkinTO,
	L2GalerkinTOFromInverse,
	adaptiveTOCollocation,

	#util.jl
    PEuclidean,
	tensor_invariants,
	dof2node,
	kmeansresult2LCS,
	getH,
	unzip,

	#velocityfields.jl
	rot_double_gyre,
	rot_double_gyre!,
	rot_double_gyreEqVari,
	rot_double_gyreEqVari!,
	bickleyJet,
	bickleyJet!,
	bickleyJetEqVari,
	bickleyJetEqVari!,
	interpolateVF,
	interp_rhs,
	interp_rhs!,
	standardMap,
	standardMapInv,
	DstandardMap,
	abcFlow,
	cylinder_flow,

	#seba.jl
	SEBA,

	#odesolvers.jl
	LinearImplicitEuler,
	LinearMEBDF2
