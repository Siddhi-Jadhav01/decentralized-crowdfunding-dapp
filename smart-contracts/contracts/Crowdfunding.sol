// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    uint256 public projectCount;

    struct Milestone {
        string title;
        uint256 amountNeeded;
        bool released;
    }

    struct Project {
        address creator;
        string title;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        uint256 raisedAmount;
        bool completed;
        bool refunded;
        Milestone[] milestones;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;

    event ProjectCreated(uint256 projectId, address creator);
    event ContributionMade(uint256 projectId, address contributor, uint256 amount);
    event MilestoneReleased(uint256 projectId, uint256 milestoneIndex, uint256 amount);
    event RefundClaimed(uint256 projectId, address contributor, uint256 amount);

    function createProject(
        string memory _title,
        string memory _description,
        uint256 _targetAmount,
        uint256 _deadline,
        Milestone[] memory _milestones
    ) public {
        require(_deadline > block.timestamp, "Invalid deadline");

        projectCount++;
        Project storage p = projects[projectCount];

        p.creator = msg.sender;
        p.title = _title;
        p.description = _description;
        p.targetAmount = _targetAmount;
        p.deadline = _deadline;

        for (uint256 i = 0; i < _milestones.length; i++) {
            p.milestones.push(
                Milestone({
                    title: _milestones[i].title,
                    amountNeeded: _milestones[i].amountNeeded,
                    released: false
                })
            );
        }

        emit ProjectCreated(projectCount, msg.sender);
    }

    function contribute(uint256 _projectId) external payable {
        Project storage p = projects[_projectId];
        require(block.timestamp < p.deadline, "Deadline over");

        contributions[_projectId][msg.sender] += msg.value;
        p.raisedAmount += msg.value;

        emit ContributionMade(_projectId, msg.sender, msg.value);
    }

    function releaseMilestone(uint256 projectId, uint256 milestoneIndex) external nonReentrant {
        Project storage p = projects[projectId];

        require(msg.sender == p.creator, "Only creator");
        require(!p.milestones[milestoneIndex].released, "Already released");

        uint256 totalNeeded = 0;
        for (uint256 i = 0; i <= milestoneIndex; i++) {
            totalNeeded += p.milestones[i].amountNeeded;
        }

        require(p.raisedAmount >= totalNeeded, "Not enough funds raised");

        p.milestones[milestoneIndex].released = true;

        payable(p.creator).transfer(p.milestones[milestoneIndex].amountNeeded);

        emit MilestoneReleased(projectId, milestoneIndex, p.milestones[milestoneIndex].amountNeeded);
    }

    function claimRefund(uint256 projectId) external nonReentrant {
        Project storage p = projects[projectId];
        require(block.timestamp >= p.deadline, "Deadline not reached");
        require(p.raisedAmount < p.targetAmount, "Target achieved");

        uint256 contributed = contributions[projectId][msg.sender];
        require(contributed > 0, "Nothing to refund");

        contributions[projectId][msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit RefundClaimed(projectId, msg.sender, contributed);
    }
}
