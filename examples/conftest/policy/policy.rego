package infracost

deny_totalDiff[msg] {
	maxDiff = 1500.0
	to_number(input.diffTotalMonthlyCost) >= maxDiff

	msg := sprintf(
		"Total monthly cost diff must be < $%.2f (actual diff is $%v)",
		[maxDiff, to_number(input.diffTotalMonthlyCost)],
	)
}

deny_instanceCost[msg] {
	r := input.projects[_].breakdown.resources[_]
	startswith(r.name, "aws_instance.")

	maxHourlyCost := 2.0
	to_number(r.hourlyCost) > maxHourlyCost

	msg := sprintf(
		"AWS instances must cost less than $%.2f\\hr (%s costs $%v\\hr).",
		[maxHourlyCost, r.name, to_number(r.hourlyCost)],
	)
}

deny_instanceCost[msg] {
	r := input.projects[_].breakdown.resources[_]
	startswith(r.name, "aws_instance.")

	baseHourlyCost := to_number(r.costComponents[_].hourlyCost)

	sr_cc := r.subresources[_].costComponents[_]
	sr_cc.name == "Provisioned IOPS"
	iopsHourlyCost := to_number(sr_cc.hourlyCost)

	iopsHourlyCost > baseHourlyCost

	msg := sprintf(
		"AWS instance IOPS must cost less than compute usage (%s IOPS $%v\\hr, usage $%v\\hr).",
		[r.name, iopsHourlyCost, baseHourlyCost],
	)
}
