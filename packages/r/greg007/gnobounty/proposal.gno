package gnobounty

import (
	"chain"
	"chain/banker"
	"time"

	"gno.land/p/nt/commondao"
	"gno.land/p/nt/ufmt"
)

// ClaimBountyProposal implements commondao.ProposalDefinition for bounty claim proposals
type ClaimBountyProposal struct {
	BountyID      uint64
	ApplicationID uint64
	Applicant     address
	PRLink        string
	title         string
	description   string
}

// NewClaimBountyProposal creates a new bounty claim proposal definition
func NewClaimBountyProposal(bountyID, applicationID uint64, applicant address, prLink string) *ClaimBountyProposal {
	return &ClaimBountyProposal{
		BountyID:      bountyID,
		ApplicationID: applicationID,
		Applicant:     applicant,
		PRLink:        prLink,
		title:         ufmt.Sprintf("Approve Application #%d for Bounty #%d", applicationID, bountyID),
		description:   ufmt.Sprintf("Review PR: %s\nApplicant: %s", prLink, applicant),
	}
}

// Title returns proposal title
func (p *ClaimBountyProposal) Title() string {
	return p.title
}

// Body returns proposal's body
func (p *ClaimBountyProposal) Body() string {
	return p.description
}

// VotingPeriod returns the period where votes are allowed after proposal creation
func (p *ClaimBountyProposal) VotingPeriod() time.Duration {
	// 7 days voting period
	return 7 * 24 * time.Hour
}

// Tally counts votes and determines if proposal passes
// Requires all 3 validators to vote YES for approval
func (p *ClaimBountyProposal) Tally(votes commondao.ReadonlyVotingRecord, members commondao.MemberSet) (bool, error) {
	totalMembers := members.Size()
	if totalMembers == 0 {
		return false, ufmt.Errorf("no members in DAO")
	}

	// Count votes using the VoteCount method
	yesCount := votes.VoteCount(commondao.ChoiceYes)
	noCount := votes.VoteCount(commondao.ChoiceNo)

	// Require 100% approval: all validators must vote YES
	// For a 3-validator DAO, we need exactly 3 YES votes
	if yesCount == totalMembers && noCount == 0 {
		return true, nil
	}

	return false, nil
}

// Execute executes the proposal after approval
func (p *ClaimBountyProposal) Execute(_ realm) error {
	app := GetApplication(p.ApplicationID)
	if app == nil {
		return ufmt.Errorf("application not found")
	}

	bounty := GetBounty(p.BountyID)
	if bounty == nil {
		return ufmt.Errorf("bounty not found")
	}

	if bounty.IsClaimed {
		return ufmt.Errorf("bounty already claimed")
	}

	// Mark application as approved
	app.Status = StatusApproved

	// Mark bounty as claimed
	bounty.IsClaimed = true
	bounty.Claimer = p.Applicant
	bounty.ClaimedAt = time.Now()

	// Transfer bounty amount to applicant
	bnk := banker.NewBanker(banker.BankerTypeRealmSend)
	send := chain.Coins{chain.Coin{Denom: "ugnot", Amount: bounty.Amount}}
	pkgAddr := chain.PackageAddress("gno.land/r/greg007/gnobounty")
	bnk.SendCoins(pkgAddr, p.Applicant, send)

	return nil
}
