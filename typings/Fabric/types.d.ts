export interface IComponentDefinition {
	// User implementations
	name: string
	reducer?: Callback
	schema?: Callback
	defaults?: Map<string, any>
	components?: Map<string, IComponentDefinition>
	refCheck?: Array<string> | Callback
	shouldUpdate?: Callback

	// Events
	onLoaded?: Callback
	onUpdated?: Callback
	initialize?: Callback
	destroy?: Callback
	render?: Callback

	effects?: Map<any, Callback>

	// Extensions
	tag?: string
	chainingEvents?: Array<string>
	isService?: boolean
}
