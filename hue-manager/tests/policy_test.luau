local t = require("./assert")
local policy = require("../lib/policy")

t.eq(policy.backoffMs(0), 1000, "attempt 0 clamps to the floor")
t.eq(policy.backoffMs(1), 1000, "first retry waits one second")
t.eq(policy.backoffMs(2), 2000, "second retry doubles")
t.eq(policy.backoffMs(3), 4000, "third retry doubles again")
t.eq(policy.backoffMs(7), 60000, "backoff caps at one minute")
t.eq(policy.backoffMs(100), 60000, "backoff stays capped")

t.finish("policy")
