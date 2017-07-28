class Hydrus::Contributor < Hydrus::GenericModel

  ####
  # Setup contributor groups data.
  ####

  # Combines a name type (personal, corporate, conference) and and role
  # (Author, Publisher, etc) into strings like this: personal_author,
  # corporate_publisher, etc.
  def self.make_role_key(name_type, role)
    "#{name_type} #{role}".parameterize.underscore
  end

  # The default role_key for a new contributor, before the user sets any values.
  @@default_role_key = make_role_key('personal', 'Author')

  def self.default_role_key
    @@default_role_key
  end

  # The data.
  @@contributor_groups = [
    {
      group_label: 'Individual',
      name_type: 'personal',
      roles: [
        'Advisor',
        'Author',
        'Collector',
        'Contributing author',
        'Creator',
        'Editor',
        'Primary advisor',
        'Principal investigator',
      ],
    },
    {
      group_label: 'Organization',
      name_type: 'corporate',
      roles: [
        'Author',
        'Contributing author',
        'Degree granting institution',
        'Distributor',
        'Publisher',
        'Sponsor',
      ],
    },
    {
      group_label: 'Event',
      name_type: 'conference',
      roles: [
        'Conference',
      ],
    },
  ]

  # Add role_key values to the data.
  @@contributor_groups.each { |cg|
    cg[:role_keys] = cg[:roles].map { |r| make_role_key(cg[:name_type], r) }
  }

  # Returns a new Contributor object, with default values.
  def self.default_contributor
    typ, role = lookup_with_role_key(@@default_role_key)
    new(
      name: '',
      role: role,
      name_type: typ
    )
  end

  # Takes a role_key. Returns the corresponding values for name type and role,
  # as a two-element array.
  def self.lookup_with_role_key(role_key = @@default_role_key)
    @@contributor_groups.each do |cg|
      role, rk = cg[:roles].zip(cg[:role_keys]).find { |r, k| k == role_key }
      return [cg[:name_type], role] if role
    end
    # If nothing found, just return the defaults.
    lookup_with_role_key()
  end

  # Returns the contributor groups data, reorganized for use in a call to
  # grouped_options_for_select() -- an array of two-element arrays, with each
  # second element being an array of ROLE-ROLEKEY pairs.
  #
  #   [ GROUP_LABEL, [ [ROLE,ROLEKEY], [ROLE,ROLEKEY], ...] ]
  #   [ GROUP_LABEL, [ [ROLE,ROLEKEY], [ROLE,ROLEKEY], ...] ]
  #   ...
  def self.groups_for_select
    @@contributor_groups.map { |cg|
      glab  = cg[:group_label]
      roles = cg[:roles]
      rks   = cg[:role_keys]
      [glab, roles.zip(rks).map { |r, k| [r, k] }]
    }
  end

  # Returns the role_key of a Contributor instance.
  def role_key
    self.class.make_role_key(name_type, role)
  end

  # Method to check for equality.
  # Used in testing.
  def ==(other)
    (
      self.name      == other.name &&
      self.role      == other.role &&
      self.name_type == other.name_type
    )
  end

  # Returns new Contributor based on attributes of self.
  # Used in testing.
  def clone
    Hydrus::Contributor.new(name: name, role: role, name_type: name_type)
  end

end
