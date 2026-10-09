public with sharing class SmartExpenseControlEngine {

    public static void validateExpenseReports(Set<Id> reportIds) {
        if (reportIds == null || reportIds.isEmpty()) {
            return;
        }

        List<Expense_Report__c> reports = [
            SELECT Id, Total_Amount__c, Status__c, Validation_Status__c, Has_Exceptions__c,
                   Travel_Request__c, Travel_Request__r.Estimated_Cost__c, Employee__c,
                   (SELECT Id, Expense_Category__c, Amount__c, Expense_Date__c, Vendor__c,
                           Paid_By__c, Receipt_Attached__c, Reimbursable_Amount__c,
                           Validation_Status__c, Policy_Result__c, Exception_Status__c, Policy_Explanation__c
                    FROM Expense_Items__r)
            FROM Expense_Report__c
            WHERE Id IN :reportIds
            WITH USER_MODE
        ];

        Map<String, Travel_Policy_Rule__mdt> policyRules = getPolicyRules();

        List<Expense_Item__c> itemsToUpdate = new List<Expense_Item__c>();
        List<Expense_Exception__c> exceptionsToInsert = new List<Expense_Exception__c>();
        List<Expense_Report__c> reportsToUpdate = new List<Expense_Report__c>();

        Set<Id> employeeIds = new Set<Id>();
        for (Expense_Report__c er : reports) {
            if (er.Employee__c != null) {
                employeeIds.add(er.Employee__c);
            }
        }

        List<Expense_Item__c> existingItems = [
            SELECT Id, Expense_Report__r.Employee__c, Expense_Category__c, Amount__c, Expense_Date__c, Vendor__c
            FROM Expense_Item__c
            WHERE Expense_Report__r.Employee__c IN :employeeIds
              AND Expense_Report__c NOT IN :reportIds
            WITH USER_MODE
        ];

        for (Expense_Report__c er : reports) {
            Boolean hasReportException = false;
            List<String> reportExceptionReasons = new List<String>();

            Decimal estBudget = (er.Travel_Request__r != null && er.Travel_Request__r.Estimated_Cost__c != null)
                ? er.Travel_Request__r.Estimated_Cost__c : 0.00;
            Decimal actualTotal = er.Total_Amount__c != null ? er.Total_Amount__c : 0.00;

            Boolean isBudgetOverrun = (estBudget > 0 && actualTotal > estBudget);

            if (er.Expense_Items__r != null) {
                for (Expense_Item__c item : er.Expense_Items__r) {
                    Boolean itemHasException = false;
                    String policyResult = 'PASS';
                    String explanation = 'Expense complies with standard policy.';
                    String severity = 'Medium';
                    String exceptionType = 'POLICY_EXCEPTION';

                    Travel_Policy_Rule__mdt rule = policyRules.get(item.Expense_Category__c);

                    // 1. Policy Limit Check
                    if (rule != null && rule.Max_Amount_Limit__c != null && item.Amount__c > rule.Max_Amount_Limit__c) {
                        itemHasException = true;
                        policyResult = 'POLICY_EXCEPTION';
                        exceptionType = 'POLICY_EXCEPTION';
                        severity = 'High';
                        explanation = 'Amount ₹' + item.Amount__c + ' exceeds category limit ₹' + rule.Max_Amount_Limit__c + ' for ' + item.Expense_Category__c + '.';
                    }
                    // 2. Receipt Requirement Check
                    else if (rule != null && rule.Require_Receipt__c && item.Receipt_Attached__c == false) {
                        if (rule.Receipt_Required_Threshold__c == null || item.Amount__c >= rule.Receipt_Required_Threshold__c) {
                            itemHasException = true;
                            policyResult = 'MISSING_RECEIPT';
                            exceptionType = 'MISSING_RECEIPT';
                            severity = 'Medium';
                            explanation = 'Receipt mandatory for ' + item.Expense_Category__c + ' expenses above ₹' + rule.Receipt_Required_Threshold__c + '.';
                        }
                    }

                    // 3. Duplicate Check
                    if (!itemHasException && er.Employee__c != null) {
                        for (Expense_Item__c exItem : existingItems) {
                            if (exItem.Expense_Report__r.Employee__c == er.Employee__c &&
                                exItem.Expense_Category__c == item.Expense_Category__c &&
                                exItem.Amount__c == item.Amount__c &&
                                item.Expense_Date__c != null && exItem.Expense_Date__c != null &&
                                Math.abs(item.Expense_Date__c.daysBetween(exItem.Expense_Date__c)) <= 3) {
                                itemHasException = true;
                                policyResult = 'POTENTIAL_DUPLICATE';
                                exceptionType = 'POTENTIAL_DUPLICATE';
                                severity = 'High';
                                explanation = 'Potential duplicate expense matching amount ₹' + item.Amount__c + ' submitted on ' + exItem.Expense_Date__c + '.';
                                break;
                            }
                        }
                    }

                    // 4. Budget Overrun Tagging
                    if (!itemHasException && isBudgetOverrun) {
                        itemHasException = true;
                        policyResult = 'BUDGET_OVERRUN';
                        exceptionType = 'BUDGET_OVERRUN';
                        severity = 'Medium';
                        explanation = 'Total report expense ₹' + actualTotal + ' exceeds approved travel estimate ₹' + estBudget + '.';
                    }

                    if (itemHasException) {
                        hasReportException = true;
                        item.Validation_Status__c = 'Exception Identified';
                        item.Policy_Result__c = policyResult;
                        item.Exception_Status__c = 'Flagged';
                        item.Policy_Explanation__c = explanation;

                        Expense_Exception__c exc = new Expense_Exception__c(
                            Expense_Item__c = item.Id,
                            Expense_Report__c = er.Id,
                            Exception_Type__c = exceptionType,
                            Severity__c = severity,
                            Status__c = 'Open',
                            Explanation__c = explanation
                        );
                        exceptionsToInsert.add(exc);
                        reportExceptionReasons.add(policyResult + ': ' + explanation);
                    } else {
                        item.Validation_Status__c = 'Pass';
                        item.Policy_Result__c = 'PASS';
                        item.Exception_Status__c = 'None';
                        item.Policy_Explanation__c = explanation;
                    }
                    itemsToUpdate.add(item);
                }
            }

            er.Has_Exceptions__c = hasReportException;
            if (hasReportException) {
                er.Validation_Status__c = 'Human Review Required';
                er.Approval_Status__c = 'Pending';
                er.Exception_Summary__c = String.join(reportExceptionReasons, ' | ');
                if (er.Exception_Summary__c != null && er.Exception_Summary__c.length() > 255) {
                    er.Exception_Summary__c = er.Exception_Summary__c.substring(0, 252) + '...';
                }
            } else {
                er.Validation_Status__c = 'Validated';
                er.Approval_Status__c = 'Approved';
                er.Status__c = 'Approved';
                er.Reimbursement_Status__c = 'Eligible';
                er.Exception_Summary__c = 'All expense items passed policy validation.';
            }
            reportsToUpdate.add(er);
        }

        if (!itemsToUpdate.isEmpty()) {
            update as user itemsToUpdate;
        }
        if (!exceptionsToInsert.isEmpty()) {
            insert as user exceptionsToInsert;
        }
        if (!reportsToUpdate.isEmpty()) {
            update as user reportsToUpdate;

            Set<Id> eligibleReportIds = new Set<Id>();
            for (Expense_Report__c er : reportsToUpdate) {
                if (er.Reimbursement_Status__c == 'Eligible') {
                    eligibleReportIds.add(er.Id);
                }
            }
            if (!eligibleReportIds.isEmpty() && !System.isQueueable() && !System.isBatch()) {
                System.enqueueJob(new ReimbursementQueueable(eligibleReportIds));
            }
        }
    }

    private static Map<String, Travel_Policy_Rule__mdt> getPolicyRules() {
        Map<String, Travel_Policy_Rule__mdt> rulesMap = new Map<String, Travel_Policy_Rule__mdt>();
        List<Travel_Policy_Rule__mdt> rules = [
            SELECT DeveloperName, Category__c, Max_Amount_Limit__c, Receipt_Required_Threshold__c,
                   Require_Receipt__c, Department__c, Is_Active__c, Rule_Description__c
            FROM Travel_Policy_Rule__mdt
            WHERE Is_Active__c = true
        ];
        for (Travel_Policy_Rule__mdt r : rules) {
            rulesMap.put(r.Category__c, r);
        }
        return rulesMap;
    }
}
