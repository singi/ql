import javascript

string chainableMethod() {
  result = "chain1" or
  result = "chain2"
}

class ApiObject extends DataFlow::NewNode {
  ApiObject() {
    this = DataFlow::moduleImport("@test/myapi").getAnInstantiation()
  }

  DataFlow::SourceNode ref(DataFlow::TypeTracker t) {
    t.start() and
    result = this
    or
    t.start() and
    result = ref(_).getAMethodCall(chainableMethod())
    or
    exists(DataFlow::TypeTracker t2 |
      result = ref(t2).track(t2, t)
    )
  }
  
  DataFlow::SourceNode ref() {
    result = ref(_)
  }
}

class Connection extends DataFlow::SourceNode {
  ApiObject api;

  Connection() {
    this = api.ref().getAMethodCall("createConnection")
  }

  DataFlow::SourceNode ref(DataFlow::TypeTracker t) {
    t.start() and
    result = this
    or
    exists(DataFlow::TypeTracker t2 |
      result = ref(t2).track(t2, t)
    )
  }
  
  DataFlow::SourceNode ref() {
    result = ref(_)
  }

  DataFlow::SourceNode getACallbackNode(DataFlow::TypeBackTracker t) {
    t.start() and
    result = ref().getAMethodCall("getData").getArgument(0).getALocalSource()
    or
    exists(DataFlow::TypeBackTracker t2 |
      result = getACallbackNode(t2).backtrack(t2, t)
    )
  }

  DataFlow::FunctionNode getACallback() {
    result = getACallbackNode(_).getAFunctionValue()
  }
}

class DataValue extends DataFlow::SourceNode {
  Connection connection;

  DataValue() {
    this = connection.getACallback().getParameter(0)
  }

  DataFlow::SourceNode ref(DataFlow::TypeTracker t) {
    t.start() and
    result = this
    or
    exists(DataFlow::TypeTracker t2 |
      result = ref(t2).track(t2, t)
    )
  }
  
  DataFlow::SourceNode ref() {
    result = ref(_)
  }
}

query DataFlow::SourceNode test_ApiObject() { result = any(ApiObject obj).ref() }

query DataFlow::SourceNode test_Connection() { result = any(Connection c).ref() }

query DataFlow::SourceNode test_DataCallback() { result = any(Connection c).getACallbackNode(_) }

query DataFlow::SourceNode test_DataValue() { result = any(DataValue v).ref() }
