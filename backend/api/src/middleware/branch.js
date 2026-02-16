const { BranchService, PrivilegeService } = require('../services');

/**
 * Validates X-Branch-Id and that the user can access the branch.
 * Use after authenticateToken. If user has privilege "all", allows any branch; otherwise requires user_branches + canLogin.
 */
const validateBranch = async (req, res, next) => {
  try {
    const branchId = req.headers['x-branch-id'];
    if (!branchId) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Branch ID is required (X-Branch-Id header)'
      });
    }

    const id = parseInt(branchId, 10);
    if (Number.isNaN(id) || id < 1) {
      return res.status(400).json({
        error: 'Bad request',
        message: 'Branch ID must be a valid positive number'
      });
    }

    const branch = await BranchService.getBranchById(branchId);
    if (!branch) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Branch not found'
      });
    }

    if (!branch.isActive) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'This branch is not active'
      });
    }

    const hasAllPrivilege = await PrivilegeService.userHasPrivilege(req.userId, 'all', 'all');
    if (!hasAllPrivilege) {
      const canAccess = await BranchService.canUserLoginToBranch(req.userId, branchId);
      if (!canAccess) {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'You do not have access to this branch'
        });
      }
    }

    req.branchId = branch.id;
    req.branch = branch;
    next();
  } catch (err) {
    console.error('Branch middleware error:', err);
    return res.status(500).json({
      error: 'Server error',
      message: 'Failed to validate branch'
    });
  }
};

module.exports = { validateBranch };
