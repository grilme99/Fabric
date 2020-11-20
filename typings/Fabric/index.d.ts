import { IComponentDefinition } from './types'

declare interface Fabric {
	DEBUG: boolean

	/**
	 * Registers a component. This function should be called before attempting to get or create the component.
	 *
	 * @param componentDefinition ComponentDefinition -- The definition of the component
	 * @return ComponentDefinition -- The passed component definition
	 */
	registerComponent(
		componentDefinition: IComponentDefinition
	): IComponentDefinition

	/**
	 * Registers all components that are immediate children of a container.
	 * Skips any test scripts (i.e. name of form `*.spec`) in the container.
	 *
	 * @param container Instance -- The container
	 * @return nil
	 */
	registerComponentsIn(container: Instance): void

	/**
	 * Returns the component associated with a component resolvable that is attached to a ref,
	 * or nil if it doesn't exist.
	 *
	 * @param componentResolvable ComponentResolvable -- The component to retrieve
	 * @param ref Ref -- The ref to retrieve the component from
	 * @return Component? -- The attached component
	 */
	getComponentByRef(
		componentResolvable: IComponentDefinition | string,
		ref: string
	): IComponentDefinition | undefined

	/** 
     * Returns the component associated with a component resolvable that is attached to ref.
	 * If it does not exist, then creates and attaches the component to ref and returns it.

	 * @param componentResolvable ComponentResolvable -- The component to retrieve
	 * @param ref Ref -- The ref to retrieve the attached component from
	 * @return Component -- The attached component
     */
	getOrCreateComponentByRef(
		componentResolvable: IComponentDefinition | string,
		ref: string
	): IComponentDefinition

	/**
	 * @param componentResolvable ComponentResolvable -- The component to retrieve
	 * @param ref Ref -- The ref to retrieve the loaded component from
	 */
	getLoadedComponentByRef(
		componentResolvable: IComponentDefinition | string,
		ref: string
	): Promise<IComponentDefinition>

	/**
	 * Removes all components attached to the passed ref.
	 *
	 * @param ref Ref -- The ref to remove all components from
	 * @return nil
	 */
	removeAllComponentsWithRef(ref: string): void

	/**
     * Fires a fabric event.

	 * @param eventName string -- The event name to fire
	 * @param ... any -- The arguments to fire the event with.
	 * @return nil
     */
	fire(eventName: string, ...args: unknown[]): void

	/**
	 * Listens to a fabric event.
	 *
	 * @param eventName string -- The event name to listen to
	 * @param callback function -- The callback fired
	 * @return nil
	 */
	on(eventName: string, callback: Callback): () => void

	/**
	 * Logs a debug message. Set fabric.DEBUG = true to enable.
	 *
	 * @param ... any -- The debug information to log
	 * @return nil
	 */
	debug(...msg: string[]): void
}

declare interface FabricConstructor {
	new (namespace?: string): Fabric
}

declare const Fabric: FabricConstructor
export = Fabric
