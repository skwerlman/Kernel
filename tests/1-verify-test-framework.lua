-- Test testing framework

test.manifest = {
    ["desc"] = "verify the testing framework works.",
    ["important"] = true,
    ["onFail"] = "Warning, the testing framework has failed. Test may not work.",
    ["shouldFail"] = false,
}

test.run = function(this)
  if this == nil then
    error("test not providing this object, got nil");
  end

  if this.manifest == nil then
    error("test manifest is empty.");
  end

  if error == nil then
    print("critical: error is not hijacked.")
    os.exit(1);
  end
end

-- return the test object
return test;
