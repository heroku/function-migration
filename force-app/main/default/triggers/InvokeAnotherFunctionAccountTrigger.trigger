trigger InvokeAnotherFunctionAccountTrigger on Account (before insert) {
	InvokeAnotherFunction.invoke();
}